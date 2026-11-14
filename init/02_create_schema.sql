\c market-lab

CREATE SCHEMA IF NOT EXISTS market;

CREATE TABLE market.securities (
    security_id SERIAL PRIMARY KEY,
    ticker TEXT UNIQUE NOT NULL,
    company_name TEXT NOT NULL,
    sector TEXT,
    cik TEXT UNIQUE
);
