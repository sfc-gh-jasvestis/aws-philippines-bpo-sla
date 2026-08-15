-- ============================================================================
-- 11_TASK_PIPELINE.SQL — Task DAG for Service Level Optimization & SLA Drift Detection
-- ============================================================================
USE DATABASE SLA_OPERATIONS;
USE SCHEMA APP;

CREATE OR REPLACE TASK APP.TASK_INGEST_INTERVALS
  WAREHOUSE = SLA_WH
  SCHEDULE = 'USING CRON */15 * * * * UTC'
  COMMENT = 'Ingest latest 15-min interval data from Kinesis'
AS
  SELECT 1; -- Replace with actual refresh logic

CREATE OR REPLACE TASK APP.TASK_DETECT_ANOMALIES
  WAREHOUSE = SLA_WH
  AFTER APP.TASK_INGEST_INTERVALS
  COMMENT = 'Run anomaly detection on latest intervals'
AS
  SELECT 1; -- Replace with actual refresh logic

CREATE OR REPLACE TASK APP.TASK_TRIGGER_REMEDIATION
  WAREHOUSE = SLA_WH
  AFTER APP.TASK_DETECT_ANOMALIES
  COMMENT = 'Trigger EventBridge remediation for confirmed drifts'
AS
  SELECT 1; -- Replace with actual refresh logic

ALTER TASK APP.TASK_TRIGGER_REMEDIATION RESUME;
ALTER TASK APP.TASK_DETECT_ANOMALIES RESUME;
ALTER TASK APP.TASK_INGEST_INTERVALS RESUME;
