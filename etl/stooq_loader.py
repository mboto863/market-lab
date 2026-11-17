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
