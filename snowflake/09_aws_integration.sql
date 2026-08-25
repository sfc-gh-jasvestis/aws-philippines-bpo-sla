-- ============================================================================
-- 09_AWS_INTEGRATION.SQL — AWS services for Service Level Optimization & SLA Drift Detection
-- Account: <YOUR_AWS_ACCOUNT_ID> | Region: ap-southeast-1
-- Skip this script for Snowflake-only build
-- ============================================================================
USE DATABASE SLA_OPERATIONS;
USE SCHEMA APP;

-- ==================== KINESIS / IOT CORE INGESTION ====================
-- Snowpipe from Kinesis Data Stream
-- Stream ARN: arn:aws:kinesis:ap-southeast-1:<YOUR_AWS_ACCOUNT_ID>:stream/aws-philippines-bpo-sla-stream

CREATE OR REPLACE PIPE RAW.REALTIME_PIPE
  AUTO_INGEST = TRUE
  INTEGRATION = 'aws_philippines_bpo_sla_S3_INT'
  COMMENT = 'Auto-ingest from Kinesis via S3 delivery stream'
AS
COPY INTO RAW.CLIENT_CONTRACTS
FROM @RAW.LANDING_STAGE/realtime/
FILE_FORMAT = (TYPE = 'JSON');

