\c market-lab

create index if not exists idx_stooq_price_raw_ticker_date
on staging.stooq_price_raw (ticker, trade_date DESC);
