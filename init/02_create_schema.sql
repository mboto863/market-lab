\c market-lab

CREATE SCHEMA IF NOT EXISTS market;

CREATE TABLE market.securities (
    security_id SERIAL PRIMARY KEY,
    ticker TEXT UNIQUE NOT NULL,
    company_name TEXT NOT NULL,
    sector TEXT,
    cik TEXT UNIQUE
);

CREATE TABLE market.price_history (
    security_id INT NOT NULL REFERENCES market.securities(security_id),
    trade_date DATE NOT NULL,
    open NUMERIC(18,6),
    high NUMERIC(18,6),
    low NUMERIC(18,6),
    close NUMERIC(18,6),
    volume BIGINT,
    PRIMARY KEY (security_id, trade_date)
)
