import os
from pathlib import Path
from io import StringIO

import pandas as pd
import psycopg
from dotenv import load_dotenv

load_dotenv()

TICKERS = ["APPL", "MSFT", "NVDA", "GOOGL", "AMZN", "META", "TSLA", "JPM", "V", "XOM"]
RAW_DIR = Path("data/stooq")
RAW_DIR.mkdir(parents=True, exist_ok=True)

def download_stooq_csv(ticker: str) -> Path:
    stooq_symbol = ticker.lower() + ".us"
    url = f"https://stooq.com/q/d/l/?s={stooq_symbol}&i=d"

    df = pd.read_csv(url)

    if "Date" not in df.columns:
        raise ValueError(f"Stooq did not return CSV data for {ticker}; possible rate limit of invalid symbol.")

    path = RAW_DIR / f"{ticker.lower()}_daily.csv"
    df.to_csv(path, index=False)
    return path

def normalize(df: pd.DataFrame, ticker: str) -> pd.DataFrame:
    df = df.rename(
        columns={
            "Date": "trade_date",
            "Open": "open",
            "High": "high",
            "Low": "low",
            "Close": "close",
            "Volume": "volume"
        }
    )

    df["ticker"] = ticker.upper()
    df["trade_date"] = pd.to_datetime(df["trade_date"]).dt.date

    numeric_columns = ["open", "high", "low", "close", "volume"]
    df[numeric_columns] = df[numeric_columns].apply(pd.to_numeric, errors="coerce")

    return df[["ticker", "trade_date", "open", "high", "low", "close", "volume"]]

def validate(df: pd.DataFrame, ticker: str) -> None:
    if df.empty:
        raise ValueError(f"No rows returned for {ticker}")

    if df["trade_date"].duplicated().any():
        raise ValueError(f"Duplicate trade dates found for {ticker}")

    bad_ohlc = (
        (df["high"] < df["low"])
        | (df["high"] < df["open"])
        | (df["high"] < df["close"])
        | (df["low"] > df["open"])
        | (df["low"] > df["close"])
    )

    if bad_ohlc.any():
        raise ValueError(f"OHLC consistency errors found for {ticker}")

    if (df[["open", "high", "low", "close"]] < 0).any().any():
        raise ValueError(f"Negative prices found for {ticker}")

def load_to_postgres(df: pd.DataFrame, conn_info: str) -> int:
    buffer = StringIO()
    df.to_csv(buffer, index=False, header=False)
    buffer.seek(0)

    with psycopg.connect(conn_info) as conn:
        with conn.cursor() as cur:
            cur.execute(
                """
                INSERT INTO market.security (ticker, company_name)
                VALUES (%s, %s)
                ON CONFLICT (ticker) DO NOTHING
                """,
                (df["ticker"].iloc[0], df["ticker"].iloc[0]),
            )

            cur.execute(
                """
                CREATE TEMP TABLE stg_price_history (
                    ticker TEXT,
                    trade_date DATE,
                    open NUMERIC,
                    low NUMERIC,
                    close NUMERIC,
                    volume BIGINT
                )
                """
            )

            cur.copy(
                buffer,
                """
                COPY stg_price_history
                FROM STDIN
                WITH (FORMAT csv)
                """
            )

            cur.execute(
                """
                    INSERT INTO market.historical_price (
                        security_id, trade_date, open, high, low, close, volume, data_source
                    )
                    SELECT
                        s.security_id,
                        t.trade_date,
                        t.open,
                        t.high,
                        t.low,
                        t.close,
                        t.volume,
                        'stooq'
                    FROM stg_price_history t
                    JOIN market.security s on s.ticker = t.ticker
                    ON CONFLICT (security_id, trade_date)
                    DO UPDATE SET
                        open = EXCLUDED.open,
                        high = EXCLUDED.high,
                        low = EXCLUDED.low,
                        close = EXCLUDED.close,
                        volume = EXCLUDED.volume,
                        data_source = EXCLUDED.data_source
                """
            )

            conn.commit()
            return cur.rowcount
