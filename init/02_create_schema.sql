\c market-lab

CREATE SCHEMA IF NOT EXISTS market;
CREATE SCHEMA IF NOT EXISTS finance;
CREATE SCHEMA IF NOT EXISTS economy;

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
);

CREATE TABLE finance.company_financials (
    financil_id BIGSERIAL PRIMARY KEY,
    security_id INT NOT NULL REFERENCES finance.securities(security_id),
    period_end DATE NOT NULL,
    fiscal_year INT NOT NULL,
    fiscal_period TEXT NOT NULL,
    revenue NUMERIC(20,2),
    net_income NUMERIC(20,2),
    total_assets NUMERIC(20,2),
    total_liabilities NUMERIC(20,2),
    operating_cash_flow NUMERIC(20,2),
    source_filing TEXT,
    loaded_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (security_id, period_end, fiscal_period, source_filing)
);

CREATE TABLE economy.macro_series (
    series_id TEXT PRIMARY KEY,
    title TEXT NOT NULL,
    units TEXT,
    frequency TEXT,
);

CREATE TABLE economy.macro_observations (
    series_id TEXT NOT NULL REFERENCES finance.macro_series(series_id),
    observation_date DATE NOT NULL,
    value NUMERIC(25,8),
    PRIMARY KEY (series_id, observation_date)
);
