-- ============================================================================
-- 10_ALERTS_NOTIFICATIONS.SQL — Alerts for Service Level Optimization & SLA Drift Detection
-- ============================================================================
USE DATABASE SLA_OPERATIONS;
USE SCHEMA APP;

-- Notification integration (email)
CREATE OR REPLACE NOTIFICATION INTEGRATION aws_philippines_bpo_sla_EMAIL_INT
  TYPE = EMAIL
  ENABLED = TRUE
  ALLOWED_RECIPIENTS = ('jonathan.asvestis@snowflake.com');

-- Alert: SLA_DRIFT_ALERT
CREATE OR REPLACE ALERT APP.SLA_DRIFT_ALERT
  WAREHOUSE = SLA_WH
  SCHEDULE = '5 MINUTE'
  COMMENT = 'SLA metric drifting toward breach'
IF (EXISTS (
  SELECT 1 FROM CURATED.SLA_HEALTH_REALTIME
  WHERE 1=1 -- Condition: IS_ANOMALY = TRUE AND DRIFT_DIRECTION = 'DEGRADING'
))
THEN
  CALL SYSTEM$SEND_EMAIL(
    'aws_philippines_bpo_sla_EMAIL_INT',
    'jonathan.asvestis@snowflake.com',
    '[ALERT] Service Level Optimization & SLA Drift Detection: SLA metric drifting toward breach',
    'SLA metric drifting toward breach'
  );

ALTER ALERT APP.SLA_DRIFT_ALERT RESUME;

-- Alert: PENALTY_THRESHOLD_ALERT
CREATE OR REPLACE ALERT APP.PENALTY_THRESHOLD_ALERT
  WAREHOUSE = SLA_WH
  SCHEDULE = '5 MINUTE'
  COMMENT = 'Projected penalty exceeds ₱500K for client'
IF (EXISTS (
  SELECT 1 FROM CURATED.SLA_HEALTH_REALTIME
  WHERE 1=1 -- Condition: PROJECTED_PENALTY > 500000
))
THEN
  CALL SYSTEM$SEND_EMAIL(
    'aws_philippines_bpo_sla_EMAIL_INT',
    'jonathan.asvestis@snowflake.com',
    '[ALERT] Service Level Optimization & SLA Drift Detection: Projected penalty exceeds ₱500K for client',
    'Projected penalty exceeds ₱500K for client'
  );

ALTER ALERT APP.PENALTY_THRESHOLD_ALERT RESUME;

