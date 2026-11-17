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
    financial_id BIGSERIAL PRIMARY KEY,
    security_id INT NOT NULL REFERENCES market.securities(security_id),
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
    frequency TEXT
);

CREATE TABLE economy.macro_observations (
    series_id TEXT NOT NULL REFERENCES economy.macro_series(series_id),
    observation_date DATE NOT NULL,
    value NUMERIC(25,8),
    PRIMARY KEY (series_id, observation_date)
);

-- Least-privilege grants
GRANT USAGE ON SCHEMA market TO app_owner, reporting;
GRANT USAGE ON SCHEMA finance TO app_owner, reporting;
GRANT USAGE ON SCHEMA economy TO app_owner, reporting;

-- Applies to tables that already exist when this script runs.
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA market TO app_owner; 
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA finance TO app_owner; 
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA economy TO app_owner; 
GRANT SELECT ON ALL TABLES IN SCHEMA market TO reporting;
GRANT SELECT ON ALL TABLES IN SCHEMA finance TO reporting;
GRANT SELECT ON ALL TABLES IN SCHEMA economy TO reporting;

-- Table privileges do not automatically include privileges on sequences backing them.
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA market TO app_owner;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA finance TO app_owner;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA economy TO app_owner;

-- Applies only to future tables created by the app_owner group;
ALTER DEFAULT PRIVILEGES IN SCHEMA market
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO app_owner;
ALTER DEFAULT PRIVILEGES IN SCHEMA finance
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO app_owner;
ALTER DEFAULT PRIVILEGES IN SCHEMA economy
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO app_owner;

-- Applies only to future tables created by the reporting group;
ALTER DEFAULT PRIVILEGES ON SCHEMA market
GRANT SELECT ON TABLES TO reporting;
ALTER DEFAULT PRIVILEGES ON SCHEMA finance
GRANT SELECT ON TABLES TO reporting;
ALTER DEFAULT PRIVILEGES ON SCHEMA economy
GRANT SELECT ON TABLES TO reporting;

-- Ingestion metadata
CREATE SCHEMA IF NOT EXISTS ingestion;

CREATE TABLE ingestion.source (
    source_id SERIAL PRIMARY KEY,
    source_name TEXT UNIQUE NOT NULL,
    description TEXT,
    base_url TEXT,
    documentation_url TEXT
);

CREATE TABLE ingestion.pipeline (
    pipeline_id SERIAL PRIMARY KEY,
    source_id INT NOT NULL REFERENCES ingestion.source(source_id),
    pipeline_name TEXT NOT NULL,
    target_schema TEXT NOT NULL,
    target_table TEXT NOT NULL,
    load_strategy TEXT NOT NULL,
    unique_key TEXT NOT NULL, -- Merge keys.
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    UNIQUE (source_id, pipeline_name)
);

CREATE TABLE ingestion.runtime (
    run_id BIGSERIAL PRIMARY KEY,
    pipeline_id INT NOT NULL REFERENCES ingestion.pipeline(pipeline_id),
    started_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    finished_at TIMESTAMPTZ,
    status TEXT NOT NULL,
    rows_head BIGINT,
    rows_accepted BIGINT,
    rows_rejected BIGINT,
    rows_inserted BIGINT,
    rows_updated BIGINT,
    error_message TEXT,
    pipeline_version TEXT,
    triggered_by TEXT
);

ALTER TABLE market.price_history
ADD COLUMN IF NOT EXISTS ingestion_run_id BIGINT REFERENCES ingestion.runtime(run_id);
