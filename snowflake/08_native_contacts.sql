-- ============================================================================
-- 08_native_contacts.sql - Snowflake-only build: live contact-centre feed without AWS.
-- Creates RAW.LIVE_CONTACTS (same columns as the Snowpipe target created by
-- aws/setup_aws.py) and APP.SIMULATE_CONTACTS(N), which inserts synthetic
-- contact events with the same value ranges and ~10% INCIDENT rate as
-- aws/publish_contacts.py. Rows are inserted directly; this simulates a program
-- contact feed and is not Snowpipe Streaming.
-- Run before 06_intelligence.sql (the alert reads RAW.LIVE_CONTACTS).
-- Idempotent: safe to run in the AWS build too.
-- ============================================================================
CREATE SCHEMA IF NOT EXISTS RAW;
CREATE SCHEMA IF NOT EXISTS APP;

CREATE TABLE IF NOT EXISTS RAW.LIVE_CONTACTS (
  PROGRAM_ID VARCHAR, EVENT_TS TIMESTAMP_NTZ, TALK_SECONDS FLOAT, QUEUE_SECONDS FLOAT,
  STATUS VARCHAR, SENT_TS TIMESTAMP_NTZ, SOURCE_FILE VARCHAR,
  LOADED_AT TIMESTAMP_LTZ DEFAULT CURRENT_TIMESTAMP());

CREATE OR REPLACE PROCEDURE APP.SIMULATE_CONTACTS(N NUMBER)
RETURNS NUMBER
LANGUAGE SQL
EXECUTE AS OWNER
AS
$$
BEGIN
  IF (N < 1 OR N > 1000) THEN
    RETURN 0;
  END IF;
  INSERT INTO RAW.LIVE_CONTACTS (PROGRAM_ID, EVENT_TS, TALK_SECONDS, QUEUE_SECONDS, STATUS, SENT_TS, SOURCE_FILE)
    WITH g AS (
      SELECT 'PG-' || LPAD(UNIFORM(0, 39, RANDOM())::VARCHAR, 4, '0') AS PROGRAM_ID,
             UNIFORM(0::FLOAT, 1::FLOAT, RANDOM()) < 0.1 AS IS_INCIDENT,
             SYSDATE() AS TS, SEQ4() AS I
      FROM TABLE(GENERATOR(ROWCOUNT => 1000))
    )
    -- NORMAL() needs constant arguments, so the incident offset is applied outside it.
    SELECT PROGRAM_ID, TS,
           ROUND(IFF(IS_INCIDENT, 840, 360) * EXP(NORMAL(0, 0.5, RANDOM())), 2),
           ROUND(IFF(IS_INCIDENT, 300, 35) * EXP(NORMAL(0, 0.4, RANDOM())), 0),
           IFF(IS_INCIDENT, 'INCIDENT', 'OK'), TS, 'APP.SIMULATE_CONTACTS'
    FROM g
    WHERE I < :N;
  RETURN SQLROWCOUNT;
END;
$$;

-- Optional continuous feed for longer demos (suspended; RESUME to start, SUSPEND after).
CREATE OR REPLACE TASK APP.TASK_SIMULATE_CONTACTS
  WAREHOUSE = __DEMO_WH__
  SCHEDULE = '1 MINUTE'
AS
  CALL APP.SIMULATE_CONTACTS(5);
