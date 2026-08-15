-- ============================================================================
-- 04_DYNAMIC_TABLES.SQL — Curated layer for Service Level Optimization & SLA Drift Detection
-- ============================================================================
USE DATABASE SLA_OPERATIONS;
USE SCHEMA CURATED;

-- SLA_HEALTH_REALTIME: Real-time SLA compliance status per client per metric
-- Source: CLIENT_CONTRACTS, SLA_METRICS, INTERVAL_PERFORMANCE
CREATE OR REPLACE DYNAMIC TABLE CURATED.SLA_HEALTH_REALTIME
  TARGET_LAG = '5 minutes'
  WAREHOUSE = SLA_WH
AS
SELECT * FROM RAW.CLIENT_CONTRACTS;
-- TODO: Replace with actual join/aggregation logic per demo

-- PENALTY_EXPOSURE: Current penalty exposure if trends continue
-- Source: CLIENT_CONTRACTS, PENALTY_HISTORY, INTERVAL_PERFORMANCE
CREATE OR REPLACE DYNAMIC TABLE CURATED.PENALTY_EXPOSURE
  TARGET_LAG = '5 minutes'
  WAREHOUSE = SLA_WH
AS
SELECT * FROM RAW.CLIENT_CONTRACTS;
-- TODO: Replace with actual join/aggregation logic per demo

-- STAFFING_GAP_ANALYSIS: Required vs actual staffing by interval and skill
-- Source: STAFFING_SCHEDULES, INTERVAL_PERFORMANCE
CREATE OR REPLACE DYNAMIC TABLE CURATED.STAFFING_GAP_ANALYSIS
  TARGET_LAG = '5 minutes'
  WAREHOUSE = SLA_WH
AS
SELECT * FROM RAW.STAFFING_SCHEDULES;
-- TODO: Replace with actual join/aggregation logic per demo

-- SLA_TIMESERIES: Hourly SLA metrics for anomaly detection input
-- Source: INTERVAL_PERFORMANCE
CREATE OR REPLACE DYNAMIC TABLE CURATED.SLA_TIMESERIES
  TARGET_LAG = '5 minutes'
  WAREHOUSE = SLA_WH
AS
SELECT * FROM RAW.INTERVAL_PERFORMANCE;
-- TODO: Replace with actual join/aggregation logic per demo

