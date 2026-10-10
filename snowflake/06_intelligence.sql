-- ============================================================================
-- 06_INTELLIGENCE.SQL - search, anomaly detection, semantic view, agent,
-- live-incident alert and on-demand refresh DAG.
-- Run with snowflake/run_intelligence.py (substitutes checked __DEMO_DB__ /
-- __DEMO_WH__ / __ALERT_EMAIL__). Requires 00-05, plus 08 (Snowflake only) or
-- aws/setup_aws.py (AWS build) for RAW.LIVE_CONTACTS.
-- Alerts and tasks are created SUSPENDED; run them with EXECUTE ALERT / EXECUTE TASK.
-- ============================================================================
USE DATABASE __DEMO_DB__;
CREATE SCHEMA IF NOT EXISTS SEARCH;
CREATE SCHEMA IF NOT EXISTS APP;

-- ---------- Synthetic incident-handling knowledge base (clearly synthetic SOPs) ----------
CREATE OR REPLACE TABLE SEARCH.INCIDENT_DOCS AS
WITH types AS (
  SELECT DISTINCT r.INCIDENT_TYPE, a.CATEGORY
  FROM RAW.PROGRAM_DAILY r JOIN RAW.PROGRAMS a ON a.ID = r.ENTITY_ID
  WHERE r.BREACH_COUNT > 0
)
SELECT
  'SOP-' || LPAD(ROW_NUMBER() OVER (ORDER BY CATEGORY, INCIDENT_TYPE)::VARCHAR, 3, '0') AS DOC_ID,
  'SOP' AS DOC_TYPE,
  CATEGORY,
  INCIDENT_TYPE,
  CATEGORY || ' - ' || INCIDENT_TYPE || ' incident handling' AS TITLE,
  'Synthetic demo SOP. Program channel: ' || CATEGORY || '. Incident type: ' || INCIDENT_TYPE || '. '
  || 'Step 1: open an incident ticket, note the affected queues and intervals, and tell the client service delivery contact. '
  || 'Step 2: ' || CASE
       WHEN INCIDENT_TYPE = 'Volume spike' THEN 'open the overflow queue to cross-skilled agents, cancel non-urgent offline activities such as coaching and huddles, and ask the workforce team to re-forecast the next four intervals.'
       WHEN INCIDENT_TYPE = 'Telephony outage' THEN 'switch inbound routing to the backup carrier or site, play the outage message on the IVR, and log the outage window with the telephony vendor ticket number.'
       WHEN INCIDENT_TYPE = 'Staffing shortfall' THEN 'call in the standby roster, approve voluntary overtime within the labour policy, and move back-office work out of the live intervals until headcount recovers.'
       WHEN INCIDENT_TYPE = 'CRM latency' THEN 'switch agents to the documented offline capture template, report the slow screens to the client IT service desk, and back-fill case notes once the CRM is responsive.'
       WHEN INCIDENT_TYPE = 'Knowledge base gap' THEN 'publish an interim answer from the subject matter expert to the team channel, tag affected cases, and request a knowledge article update from the client.'
       WHEN INCIDENT_TYPE = 'Network link down' THEN 'fail over to the backup link, confirm that agent desktops and softphones reconnect, and escalate to the network operations centre if the backup link is also down.'
       WHEN INCIDENT_TYPE = 'Escalation backlog' THEN 'assign a team lead to triage the oldest escalations first, confirm the client escalation contacts, and send the client an updated resolution estimate.'
       ELSE 'review the incident against the program profile and escalate if unexplained.'
     END
  || ' Step 3: if the abandon rate stays above 8% or average handle time stays above 15 minutes after the fix, keep the ticket open and request a program review. '
  || 'Step 4: record the resolution; if the daily service-level target was missed or a client penalty notice is likely, log it for the weekly client service review.' AS CONTENT
FROM types;

CREATE OR REPLACE CORTEX SEARCH SERVICE SEARCH.INCIDENT_SOP_SEARCH
  ON CONTENT
  ATTRIBUTES CATEGORY, INCIDENT_TYPE
  WAREHOUSE = __DEMO_WH__
  TARGET_LAG = '7 days'
AS (SELECT DOC_ID, TITLE, CATEGORY, INCIDENT_TYPE, CONTENT FROM SEARCH.INCIDENT_DOCS);

-- ---------- Abandon-rate anomaly detection (train first 75 days, detect last 15) ----------
CREATE OR REPLACE VIEW ML.ABANDON_SERIES AS
SELECT ENTITY_ID, EVENT_DATE::TIMESTAMP_NTZ AS TS, ABANDON_PCT::FLOAT AS ABANDON_RATE
FROM RAW.PROGRAM_DAILY;
CREATE OR REPLACE VIEW ML.ABANDON_TRAIN AS
SELECT * FROM ML.ABANDON_SERIES WHERE TS < (SELECT DATEADD(day, -15, MAX(TS)) FROM ML.ABANDON_SERIES);
CREATE OR REPLACE VIEW ML.ABANDON_DETECT AS
SELECT * FROM ML.ABANDON_SERIES WHERE TS >= (SELECT DATEADD(day, -15, MAX(TS)) FROM ML.ABANDON_SERIES);

CREATE OR REPLACE SNOWFLAKE.ML.ANOMALY_DETECTION ML.ABANDON_ANOMALY_MODEL(
  INPUT_DATA => SYSTEM$REFERENCE('VIEW', 'ML.ABANDON_TRAIN'),
  SERIES_COLNAME => 'ENTITY_ID', TIMESTAMP_COLNAME => 'TS', TARGET_COLNAME => 'ABANDON_RATE',
  LABEL_COLNAME => '');

CREATE OR REPLACE TABLE ML.ABANDON_ANOMALIES AS
SELECT SERIES::VARCHAR AS ENTITY_ID, TS::DATE AS EVENT_DATE, Y AS ABANDON_RATE, FORECAST AS EXPECTED,
       LOWER_BOUND, UPPER_BOUND, IS_ANOMALY, PERCENTILE
FROM TABLE(ML.ABANDON_ANOMALY_MODEL!DETECT_ANOMALIES(
  INPUT_DATA => SYSTEM$REFERENCE('VIEW', 'ML.ABANDON_DETECT'),
  SERIES_COLNAME => 'ENTITY_ID', TIMESTAMP_COLNAME => 'TS', TARGET_COLNAME => 'ABANDON_RATE'));

-- ---------- Semantic view ----------
CREATE OR REPLACE SEMANTIC VIEW APP.SLA_ANALYTICS
  TABLES (
    programs AS CURATED.PERFORMANCE_SUMMARY PRIMARY KEY (ENTITY_ID)
      WITH SYNONYMS = ('entities', 'programs', 'client programs')
      COMMENT = 'One row per fictional BPO client program served from a Philippine city, 90-day totals',
    risk AS ML.BREACH_RISK_SCORES PRIMARY KEY (ENTITY_ID)
      COMMENT = 'Latest next-7-day SLA-breach probability per program',
    incidents AS CURATED.INCIDENT_SUMMARY PRIMARY KEY (INCIDENT_TYPE)
      COMMENT = 'Incidents, SLA breaches and client penalty notices by incident type, 90 days',
    daily AS CURATED.TREND_ANALYSIS PRIMARY KEY (METRIC_DATE)
      COMMENT = 'Network-wide totals per day'
  )
  RELATIONSHIPS (risk_program AS risk (ENTITY_ID) REFERENCES programs)
  FACTS (
    programs.incidents_f AS INCIDENT_COUNT,
    programs.breach_f AS BREACH_COUNT,
    programs.penalty_f AS PENALTY_COUNT,
    programs.contacts_f AS CONTACT_COUNT,
    programs.value_f AS BILLABLE_PHP,
    programs.audit_due_f AS AUDIT_DUE,
    programs.audit_done_f AS AUDIT_COMPLETED,
    risk.breach_prob_f AS BREACH_PROB_7D,
    incidents.type_incidents_f AS INCIDENT_COUNT,
    incidents.type_breached_f AS BREACH_COUNT,
    incidents.type_penalties_f AS PENALTY_COUNT,
    incidents.type_value_f AS EXPOSED_BILLABLE_PHP,
    daily.day_incidents_f AS INCIDENT_COUNT,
    daily.day_breached_f AS BREACH_COUNT,
    daily.day_value_f AS BILLABLE_PHP
  )
  DIMENSIONS (
    programs.program_id AS ENTITY_ID WITH SYNONYMS = ('program', 'client program', 'program code', 'entity'),
    programs.program_name AS ENTITY_NAME,
    programs.city AS REGION WITH SYNONYMS = ('city', 'region', 'location')
      COMMENT = 'Philippine city that serves the program',
    programs.channel AS CATEGORY WITH SYNONYMS = ('channel', 'line of business', 'program type'),
    programs.risk_tier AS RISK_TIER COMMENT = 'Client account risk tier 1 (low) to 3 (high)',
    risk.risk_band AS RISK_BAND COMMENT = 'High >= 0.5, Medium >= 0.25, else Low',
    risk.scored_as_of AS SCORED_AS_OF,
    incidents.incident_type AS INCIDENT_TYPE WITH SYNONYMS = ('incident', 'incident reason', 'disruption type'),
    daily.metric_date AS METRIC_DATE
  )
  METRICS (
    programs.program_total AS COUNT(programs.program_id)
      WITH SYNONYMS = ('number of programs', 'number of entities', 'how many programs'),
    programs.incident_free_pct AS 100 * (SUM(programs.contacts_f) - SUM(programs.incidents_f)) / NULLIF(SUM(programs.contacts_f), 0)
      WITH SYNONYMS = ('incident-free contact rate', 'incident-free rate')
      COMMENT = 'Contacts not touched by an incident / contacts handled',
    programs.breach_share_pct AS 100 * SUM(programs.breach_f) / NULLIF(SUM(programs.incidents_f), 0)
      COMMENT = 'SLA-breach incidents / incidents raised',
    programs.incidents_raised AS SUM(programs.incidents_f) WITH SYNONYMS = ('incidents', 'incident volume'),
    programs.sla_breach_incidents AS SUM(programs.breach_f) WITH SYNONYMS = ('SLA breaches', 'missed service level'),
    programs.penalty_notices AS SUM(programs.penalty_f) WITH SYNONYMS = ('penalty notices', 'client penalties'),
    programs.contacts_handled AS SUM(programs.contacts_f),
    programs.total_billable_php AS SUM(programs.value_f) WITH SYNONYMS = ('billable value', 'billings in PHP'),
    programs.audit_compliance_pct AS 100 * SUM(programs.audit_done_f) / NULLIF(SUM(programs.audit_due_f), 0)
      COMMENT = 'QA calibration audits completed / audits due',
    risk.avg_breach_prob AS AVG(risk.breach_prob_f),
    incidents.type_incidents AS SUM(incidents.type_incidents_f),
    incidents.type_breached AS SUM(incidents.type_breached_f),
    incidents.type_penalties AS SUM(incidents.type_penalties_f),
    incidents.type_breached_share_pct AS 100 * SUM(incidents.type_breached_f) / NULLIF(SUM(incidents.type_incidents_f), 0),
    daily.daily_incidents AS SUM(daily.day_incidents_f),
    daily.daily_breached AS SUM(daily.day_breached_f),
    daily.daily_billable_php AS SUM(daily.day_value_f)
  )
  COMMENT = 'Synthetic Philippine BPO client SLA operations analytics (demo)';

-- ---------- Cortex Agent ----------
CREATE OR REPLACE AGENT APP.SLA_AGENT
  COMMENT = 'Client SLA assistant over the client programs of a fictional Philippine BPO'
  FROM SPECIFICATION
$$
models:
  orchestration: claude-sonnet-4-5
instructions:
  response: "Answer only from tool results. State that data is synthetic. Give program IDs and numbers with units (PHP, %)."
  orchestration: "Use program_analyst for programs, cities, channels, contacts handled, billable value, incidents, SLA breaches, penalty notices, QA calibration compliance, incident types and SLA-breach risk. Use sop_search for incident-handling procedures."
tools:
  - tool_spec:
      type: cortex_analyst_text_to_sql
      name: program_analyst
      description: "Program count, contacts handled, billable value in PHP, incidents, SLA breaches, client penalty notices, incident-free contact rate, QA calibration compliance, incident types and SLA-breach risk scores by program, city and channel"
  - tool_spec:
      type: cortex_search
      name: sop_search
      description: "Synthetic client-program incident-handling SOPs by channel and incident type"
tool_resources:
  program_analyst:
    semantic_view: __DEMO_DB__.APP.SLA_ANALYTICS
    execution_environment:
      type: warehouse
      warehouse: __DEMO_WH__
  sop_search:
    name: __DEMO_DB__.SEARCH.INCIDENT_SOP_SEARCH
    max_results: 3
    id_column: DOC_ID
    title_column: TITLE
$$;
-- ---------- Live-incident alert ----------
CREATE TABLE IF NOT EXISTS APP.ALERT_LOG (
  ALERTED_AT TIMESTAMP_LTZ DEFAULT CURRENT_TIMESTAMP(), PROGRAM_ID VARCHAR,
  EVENT_TS TIMESTAMP_NTZ, TALK_SECONDS FLOAT, QUEUE_SECONDS FLOAT, SOP_HINT VARCHAR);

CREATE OR REPLACE NOTIFICATION INTEGRATION PH_BPO_SLA_EMAIL_INT
  TYPE = EMAIL ENABLED = TRUE ALLOWED_RECIPIENTS = ('__ALERT_EMAIL__');

CREATE OR REPLACE PROCEDURE APP.LOG_LIVE_ALERTS()
RETURNS NUMBER
LANGUAGE SQL
EXECUTE AS OWNER
AS
$$
DECLARE
  n NUMBER;
BEGIN
  INSERT INTO APP.ALERT_LOG (PROGRAM_ID, EVENT_TS, TALK_SECONDS, QUEUE_SECONDS, SOP_HINT)
    SELECT p.PROGRAM_ID, p.EVENT_TS, p.TALK_SECONDS, p.QUEUE_SECONDS,
           'Check ' || r.CATEGORY || ' incident SOPs; current risk band ' || COALESCE(s.RISK_BAND, 'n/a')
    FROM RAW.LIVE_CONTACTS p
    JOIN RAW.PROGRAMS r ON r.ID = p.PROGRAM_ID
    LEFT JOIN ML.BREACH_RISK_SCORES s ON s.ENTITY_ID = p.PROGRAM_ID
    WHERE p.STATUS = 'INCIDENT'
      AND NOT EXISTS (SELECT 1 FROM APP.ALERT_LOG l WHERE l.PROGRAM_ID = p.PROGRAM_ID AND l.EVENT_TS = p.EVENT_TS);
  n := SQLROWCOUNT;
  IF (n > 0) THEN
    CALL SYSTEM$SEND_EMAIL('PH_BPO_SLA_EMAIL_INT', '__ALERT_EMAIL__',
      '[Demo] Client program incident alert',
      'New live contact-centre incidents logged in APP.ALERT_LOG: ' || :n || '. Data is synthetic.');
  END IF;
  RETURN n;
END;
$$;

CREATE OR REPLACE ALERT APP.LIVE_INCIDENT_ALERT
  WAREHOUSE = __DEMO_WH__
  SCHEDULE = '5 MINUTE'
  IF (EXISTS (
    SELECT 1 FROM RAW.LIVE_CONTACTS p
    WHERE p.STATUS = 'INCIDENT'
      AND NOT EXISTS (SELECT 1 FROM APP.ALERT_LOG l WHERE l.PROGRAM_ID = p.PROGRAM_ID AND l.EVENT_TS = p.EVENT_TS)))
  THEN CALL APP.LOG_LIVE_ALERTS();

-- ---------- On-demand refresh DAG (suspended; run with EXECUTE TASK APP.TASK_REFRESH_CURATED) ----------
CREATE OR REPLACE PROCEDURE APP.REFRESH_CURATED()
RETURNS VARCHAR
LANGUAGE SQL
EXECUTE AS OWNER
AS
$$
BEGIN
  ALTER DYNAMIC TABLE CURATED.PERFORMANCE_SUMMARY REFRESH;
  ALTER DYNAMIC TABLE CURATED.TREND_ANALYSIS REFRESH;
  ALTER DYNAMIC TABLE CURATED.INCIDENT_SUMMARY REFRESH;
  ALTER DYNAMIC TABLE CURATED.KPI_SUMMARY REFRESH;
  RETURN 'refreshed';
END;
$$;

CREATE OR REPLACE TASK APP.TASK_REFRESH_CURATED
  WAREHOUSE = __DEMO_WH__
AS
  CALL APP.REFRESH_CURATED();

CREATE OR REPLACE TASK APP.TASK_RESCORE_RISK
  WAREHOUSE = __DEMO_WH__
  AFTER APP.TASK_REFRESH_CURATED
AS
  CREATE OR REPLACE TABLE ML.BREACH_RISK_SCORES COPY GRANTS AS
  WITH latest AS (
    SELECT * FROM ML.BREACH_FEATURES QUALIFY ROW_NUMBER() OVER (PARTITION BY ENTITY_ID ORDER BY EVENT_DATE DESC) = 1
  ), p AS (
    SELECT ENTITY_ID, EVENT_DATE,
           ML.BREACH_RISK_MODEL!PREDICT(INPUT_DATA => OBJECT_CONSTRUCT(
             'CATEGORY', CATEGORY, 'RISK_TIER', RISK_TIER, 'PROGRAM_AGE_YEARS', PROGRAM_AGE_YEARS,
             'ABANDON_PCT', ABANDON_PCT, 'AVG_HANDLE_MIN', AVG_HANDLE_MIN,
             'ABANDON_7D', ABANDON_7D, 'BREACH_30D', BREACH_30D)) AS PRED
    FROM latest
  )
  SELECT ENTITY_ID, EVENT_DATE AS SCORED_AS_OF, ROUND(PRED:probability:BREACH::FLOAT, 4) AS BREACH_PROB_7D,
         CASE WHEN PRED:probability:BREACH::FLOAT >= 0.5 THEN 'High'
              WHEN PRED:probability:BREACH::FLOAT >= 0.25 THEN 'Medium' ELSE 'Low' END AS RISK_BAND,
         CURRENT_TIMESTAMP() AS SCORED_AT
  FROM p;
