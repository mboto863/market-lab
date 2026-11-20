\c market-lab

create schema if not exists market;
create schema if not exists finance;
create schema if not exists economy;


-- Least-privilege grants
grant usage on schema market to app_owner, reporting;
grant usage on schema finance to app_owner, reporting;
grant usage on schema economy to app_owner, reporting;


-- Applies only to future tables created by the app_owner group;
alter default privileges in schema market
grant select, insert, update, delete on tables to app_owner;
alter default privileges in schema finance
grant select, insert, update, delete on tables to app_owner;
alter default privileges in schema economy
grant select, insert, update, delete on tables to app_owner;

-- Applies only to future tables created by the reporting group;
alter default privileges in schema market
grant select on tables to reporting;
alter default privileges in schema finance
grant select on tables to reporting;
alter default privileges in schema economy
grant select on tables to reporting;

-- Ingestion metadata
create schema if not exists ingestion;

-- Ingestion metadata writable only by the etl role. analysts should be able to
-- Inspect pipeline health, but not alter the audit trail.
grant usage on schema ingestion to app_owner, reporting;

-- A staging schema for preserving raw data.
create schema if not exists staging;
