-- ============================================================================
-- 03_STAGING.SQL — Generate synthetic data for Service Level Optimization & SLA Drift Detection
-- Country: PHILIPPINES | Currency: PHP
-- ============================================================================
USE DATABASE SLA_OPERATIONS;
USE SCHEMA RAW;

-- Data generation scripts are demo-specific.
-- See the handcrafted SQL in the aws-malaysia-semiconductor-yield demo for
-- the full pattern: GENERATOR + UNIFORM + LATERAL for distribution,
-- Cortex Complete for text generation, engineered key demo numbers.

-- Target row counts:
-- CLIENT_CONTRACTS: 42 rows — Client SLA contracts with penalty clauses
-- SLA_METRICS: 200 rows — SLA metric definitions per client (AHT, ASA, FCR, CSAT, abandon)
-- INTERVAL_PERFORMANCE: 1,200,000 rows — 15-minute interval operational metrics from Kinesis
-- STAFFING_SCHEDULES: 95,000 rows — Agent shift schedules and actual attendance
-- PENALTY_HISTORY: 380 rows — Historical SLA penalty incidents and credits issued
-- CLOUDWATCH_ALARMS: 15,000 rows — AWS CloudWatch operational alarms from contact center infra
