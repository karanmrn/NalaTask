-- PROPOSED INPUT CONTRACT ONLY. Do not execute without Finance/platform approval.
-- Populate with an approved source; the assessment provides no FX dataset.
create table if not exists RAW.REFERENCE.DAILY_FX_RATES (
    rate_date date not null,
    currency varchar not null,
    usd_per_unit number(38,12) not null,
    rate_source varchar not null
);
-- Uniqueness is checked in dbt; this DDL supplies no invented rates.
