\c market-lab

create table market.security (
    security_id serial primary key,
    ticker text unique not null,
    company_name text not null,
    sector text,
    cik text unique
);

create table market.historical_price (
    security_id int not null references market.security(security_id),
    trade_date date not null,
    open numeric(18,6),
    high numeric(18,6),
    low numeric(18,6),
    close numeric(18,6),
    volume bigint,
    primary key (security_id, trade_date)
);

create table finance.company_financials (
    financial_id bigserial primary key,
    security_id int not null references market.security(security_id),
    period_end date not null,
    fiscal_year int not null,
    fiscal_period text not null,
    revenue numeric(20,2),
    net_income numeric(20,2),
    total_assets numeric(20,2),
    total_liabilities numeric(20,2),
    operating_cash_flow numeric(20,2),
    source_filing text,
    loaded_at timestamptz not null default now(),
    unique (security_id, period_end, fiscal_period, source_filing)
);

create table economy.macro_series (
    series_id text primary key,
    title text not null,
    units text,
    frequency text
);

create table economy.macro_observation (
    series_id text not null references economy.macro_series(series_id),
    observation_date date not null,
    value numeric(25,8),
    primary key (series_id, observation_date)
);

-- Applies to tables that already exist when this script runs.
grant select, insert, update, delete on all tables in schema market to app_owner; 
grant select, insert, update, delete on all tables in schema finance to app_owner; 
grant select, insert, update, delete on all tables in schema economy to app_owner; 
grant select on all tables in schema market to reporting;
grant select on all tables in schema finance to reporting;
grant select on all tables in schema economy to reporting;

-- Table privileges do not automatically include privileges on sequences backing them.
grant usage, select on all sequences in schema market to app_owner;
grant usage, select on all sequences in schema finance to app_owner;
grant usage, select on all sequences in schema economy to app_owner;

create table ingestion.source (
    source_id serial primary key,
    source_name text unique not null,
    description text,
    base_url text,
    documentation_url text
);

create table ingestion.pipeline (
    pipeline_id serial primary key,
    source_id int not null references ingestion.source(source_id),
    pipeline_name text not null,
    target_schema text not null,
    target_table text not null,
    load_strategy text not null,
    unique_key text not null, -- merge keys.
    is_active boolean not null default true,
    unique (source_id, pipeline_name)
);

create table ingestion.runtime (
    run_id bigserial primary key,
    pipeline_id int not null references ingestion.pipeline(pipeline_id),
    started_at timestamptz not null default now(),
    finished_at timestamptz,
    status text not null,
    rows_head bigint,
    rows_accepted bigint,
    rows_rejected bigint,
    rows_inserted bigint,
    rows_updated bigint,
    error_message text,
    pipeline_version text,
    triggered_by text
);

alter table market.historical_price
add column if not exists ingestion_run_id bigint references ingestion.runtime(run_id);

-- Ingestion metadata writable only by the etl role. analysts should be able to
-- Inspect pipeline health, but not alter the audit trail.
grant select on all tables in schema ingestion to reporting;

grant select, insert, update on all tables in schema ingestion to app_owner;
grant usage, select on all sequences in schema ingestion to app_owner;

create table staging.stooq_price_raw (
    ticker text not null,
    trade_date date not null,
    open numeric,
    high numeric,
    low numeric,
    close numeric,
    volume bigint,
    source_file text not null,
    loaded_at timestamptz not null default now(),
    primary key (ticker, trade_date)
);
