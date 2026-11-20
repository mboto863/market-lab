\c market-lab

create schema if not exists staging;

create table if not exists staging.stooq_price_raw (
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

create index if not exists idx_stooq_price_raw_ticker_date
on staging.stooq_price_raw (ticker, trade_date desc);
