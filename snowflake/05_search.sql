-- ============================================================================
-- 05_SEARCH.SQL — Cortex Search for Service Level Optimization & SLA Drift Detection
-- ============================================================================
USE DATABASE SLA_OPERATIONS;
USE SCHEMA SEARCH;

CREATE OR REPLACE CORTEX SEARCH SERVICE SEARCH.SLA_CONTRACT_SEARCH
  ON CONTRACT_TERMS
  ATTRIBUTES CLIENT_ID, PENALTY_TYPE, METRIC_TYPE
  WAREHOUSE = SLA_WH
  TARGET_LAG = '1 hour'
AS (
  SELECT * FROM RAW.CLIENT_CONTRACTS
);
