-- ============================================================================
-- 07_SEMANTIC_VIEW.SQL — Semantic View for Service Level Optimization & SLA Drift Detection
-- ============================================================================
USE DATABASE SLA_OPERATIONS;
USE SCHEMA APP;

CREATE OR REPLACE SEMANTIC VIEW APP.SLA_OPERATIONS_ANALYTICS
  COMMENT = 'SLA compliance, penalty exposure, staffing, and drift analytics'
AS
  TABLES (
    CURATED.SLA_HEALTH_REALTIME AS sla_health_realtime,CURATED.PENALTY_EXPOSURE AS penalty_exposure,CURATED.STAFFING_GAP_ANALYSIS AS staffing_gap_analysis,CURATED.SLA_TIMESERIES AS sla_timeseries
  );
