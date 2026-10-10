-- Synthetic program-day observations for a fictional Philippine BPO's client programs.
-- A program is one fictional client line of business served from one of five
-- Philippine cities. Nothing is seeded as a prediction. Randomness is HASH-seeded,
-- so every rebuild is reproducible: per-program breach propensity, drift between
-- QA calibration audits, missed audits, channel-weighted incident types, incidents
-- resolved without an SLA breach, and two city-wide power interruptions.
USE DATABASE IDENTIFIER($DEMO_DB);
USE SCHEMA RAW;
USE WAREHOUSE IDENTIFIER($DEMO_WH);

CREATE TABLE RAW.PROGRAMS AS
WITH programs AS (
  SELECT ROW_NUMBER() OVER (ORDER BY SEQ4()) - 1 AS PROGRAM_INDEX
  FROM TABLE(GENERATOR(ROWCOUNT => 40))
), draws AS (
  SELECT PROGRAM_INDEX,
         MOD(ABS(HASH(PROGRAM_INDEX, 'phsla-age')), 1000000) / 1e6 AS U_AGE,
         MOD(ABS(HASH(PROGRAM_INDEX, 'phsla-rate')), 1000000) / 1e6 AS U_RATE,
         MOD(ABS(HASH(PROGRAM_INDEX, 'phsla-audit')), 1000000) / 1e6 AS U_AUDIT,
         MOD(ABS(HASH(PROGRAM_INDEX, 'phsla-discipline')), 1000000) / 1e6 AS U_DISCIPLINE,
         MOD(ABS(HASH(PROGRAM_INDEX, 'phsla-tier')), 1000000) / 1e6 AS U_TIER
  FROM programs
)
SELECT 'PG-' || LPAD(PROGRAM_INDEX::VARCHAR, 4, '0') AS ID,
       'Synthetic program ' || LPAD(PROGRAM_INDEX::VARCHAR, 4, '0') AS NAME,
       -- Deterministic spread (5 and 8 are coprime): every city and channel is present.
       CASE MOD(PROGRAM_INDEX, 5) WHEN 0 THEN 'Taguig City' WHEN 1 THEN 'Cebu City'
            WHEN 2 THEN 'Pasig City' WHEN 3 THEN 'Davao City' ELSE 'Bacolod City' END AS REGION,
       CASE MOD(PROGRAM_INDEX, 8) WHEN 0 THEN 'Voice inbound' WHEN 1 THEN 'Voice inbound'
            WHEN 2 THEN 'Voice inbound' WHEN 3 THEN 'Chat support' WHEN 4 THEN 'Chat support'
            WHEN 5 THEN 'Technical support' WHEN 6 THEN 'Back-office processing' ELSE 'Email support' END AS CATEGORY,
       PROGRAM_INDEX,
       1 + FLOOR(U_TIER * 3) AS RISK_TIER,
       ROUND(0.5 + U_AGE * 9.5, 1) AS PROGRAM_AGE_YEARS,
       -- Base daily probability of an SLA-breach incident 0.6%-3.1%;
       -- ~14% of programs are chronically weak (x3).
       (0.006 + U_RATE * 0.025) * IFF(U_RATE > 0.86, 3, 1) AS BASE_BREACH_RATE,
       7 * (1 + FLOOR(U_AUDIT * 3)) AS AUDIT_INTERVAL_DAYS,
       0.5 + U_DISCIPLINE * 0.5 AS AUDIT_COMPLETION_PROB,
       'Active' AS STATUS
FROM draws;

CREATE TABLE RAW.PROGRAM_DAILY AS
WITH days AS (
  SELECT ROW_NUMBER() OVER (ORDER BY SEQ4()) - 1 AS DAY_INDEX
  FROM TABLE(GENERATOR(ROWCOUNT => 90))
), city_events AS (
  -- Two city-wide power interruptions; every program in the city raises an
  -- incident that is resolved on generator power without an SLA breach.
  SELECT * FROM VALUES (27, 'Cebu City'), (63, 'Davao City') AS o(DAY_INDEX, REGION)
), base AS (
  SELECT r.ID AS ENTITY_ID, r.PROGRAM_INDEX, r.CATEGORY, r.REGION, r.PROGRAM_AGE_YEARS,
         r.BASE_BREACH_RATE, r.AUDIT_INTERVAL_DAYS, r.AUDIT_COMPLETION_PROB,
         d.DAY_INDEX,
         DATEADD('day', d.DAY_INDEX - 89, CURRENT_DATE()) AS EVENT_DATE,
         MOD(d.DAY_INDEX + r.PROGRAM_INDEX * 3, r.AUDIT_INTERVAL_DAYS) AS DAYS_SINCE_AUDIT,
         MOD(ABS(HASH(r.ID, d.DAY_INDEX, 'phsla-breach')), 1000000) / 1e6 AS U_FAIL,
         MOD(ABS(HASH(r.ID, d.DAY_INDEX, 'phsla-detect')), 1000000) / 1e6 AS U_DETECT,
         MOD(ABS(HASH(r.ID, d.DAY_INDEX, 'phsla-clear')), 1000000) / 1e6 AS U_CLEAR,
         MOD(ABS(HASH(r.ID, d.DAY_INDEX, 'phsla-type')), 1000000) / 1e6 AS U_TYPE,
         MOD(ABS(HASH(r.ID, d.DAY_INDEX, 'phsla-done')), 1000000) / 1e6 AS U_DONE,
         MOD(ABS(HASH(r.ID, d.DAY_INDEX, 'phsla-volume')), 1000000) / 1e6 AS U_VOLUME,
         MOD(ABS(HASH(r.ID, d.DAY_INDEX, 'phsla-noise')), 1000000) / 1e6 AS U_NOISE,
         MOD(ABS(HASH(r.ID, d.DAY_INDEX, 'phsla-penalty')), 1000000) / 1e6 AS U_SLA,
         e.REGION IS NOT NULL AS CITY_EVENT
  FROM RAW.PROGRAMS r CROSS JOIN days d
  LEFT JOIN city_events e ON e.DAY_INDEX = d.DAY_INDEX AND e.REGION = r.REGION
), audit AS (
  SELECT *,
         IFF(DAYS_SINCE_AUDIT = 0, 1, 0) AS AUDIT_DUE,
         IFF(DAYS_SINCE_AUDIT = 0 AND U_DONE < AUDIT_COMPLETION_PROB, 1, 0) AS AUDIT_COMPLETED,
         -- Agent quality drifts between QA calibration audits; weak discipline carries it over.
         DAYS_SINCE_AUDIT / AUDIT_INTERVAL_DAYS + (1 - AUDIT_COMPLETION_PROB) AS DRIFT
  FROM base
), breaches AS (
  SELECT *,
         CASE WHEN U_FAIL < LEAST(0.5, BASE_BREACH_RATE * (0.4 + 1.6 * DRIFT) * (1 + 1 / (1 + PROGRAM_AGE_YEARS / 2))) / 4 THEN 2
              WHEN U_FAIL < LEAST(0.5, BASE_BREACH_RATE * (0.4 + 1.6 * DRIFT) * (1 + 1 / (1 + PROGRAM_AGE_YEARS / 2))) THEN 1
              ELSE 0 END AS BREACH_RISK_COUNT
  FROM audit
), incidents AS (
  SELECT *,
         -- About 82% of at-risk days raise an incident that misses the daily
         -- service-level target; the rest recover within the day.
         IFF(CITY_EVENT, 0, IFF(U_DETECT < 0.82, BREACH_RISK_COUNT, 0)) AS BREACH_COUNT,
         -- Incidents resolved without an SLA breach: higher for high-volume channels.
         IFF(CITY_EVENT, 1, IFF(U_CLEAR < CASE CATEGORY WHEN 'Email support' THEN 0.18
                                                        WHEN 'Chat support' THEN 0.15
                                                        WHEN 'Technical support' THEN 0.10 ELSE 0.08 END, 1, 0)) AS CLEARED_COUNT
  FROM breaches
), measured AS (
  SELECT *,
         BREACH_COUNT + CLEARED_COUNT AS INCIDENT_COUNT,
         ROUND(CASE CATEGORY WHEN 'Email support' THEN 1250 WHEN 'Chat support' THEN 1750
                             WHEN 'Technical support' THEN 880 WHEN 'Back-office processing' THEN 640
                             ELSE 2150 END
               * (0.7 + 0.6 * U_VOLUME) * (1 + 0.6 * BREACH_RISK_COUNT)) AS CONTACT_COUNT,
         CASE CATEGORY WHEN 'Email support' THEN 41 WHEN 'Chat support' THEN 47
                       WHEN 'Technical support' THEN 96 WHEN 'Back-office processing' THEN 37 ELSE 63 END
           * (0.85 + 0.3 * U_NOISE) AS AVG_RATE_PHP
  FROM incidents
)
SELECT ENTITY_ID || '-' || TO_CHAR(EVENT_DATE, 'YYYYMMDD') AS EVENT_ID,
       ENTITY_ID, EVENT_DATE,
       CONTACT_COUNT,
       ROUND(CONTACT_COUNT * AVG_RATE_PHP, 2) AS BILLABLE_PHP,
       INCIDENT_COUNT, BREACH_COUNT,
       IFF(BREACH_COUNT > 0 AND U_SLA < 0.55, 1, 0) AS PENALTY_FLAGGED,
       CASE WHEN INCIDENT_COUNT = 0 THEN 'None'
            WHEN CITY_EVENT THEN 'Area power interruption'
            WHEN CATEGORY = 'Voice inbound' THEN IFF(U_TYPE < 0.45, 'Volume spike', IFF(U_TYPE < 0.8, 'Telephony outage', 'Staffing shortfall'))
            WHEN CATEGORY = 'Chat support' THEN IFF(U_TYPE < 0.45, 'Staffing shortfall', IFF(U_TYPE < 0.8, 'Volume spike', 'CRM latency'))
            WHEN CATEGORY = 'Technical support' THEN IFF(U_TYPE < 0.55, 'Knowledge base gap', 'Escalation backlog')
            WHEN CATEGORY = 'Back-office processing' THEN IFF(U_TYPE < 0.45, 'Network link down', IFF(U_TYPE < 0.8, 'Escalation backlog', 'Staffing shortfall'))
            ELSE IFF(U_TYPE < 0.5, 'Volume spike', IFF(U_TYPE < 0.75, 'CRM latency', 'Network link down')) END AS INCIDENT_TYPE,
       AUDIT_DUE, AUDIT_COMPLETED,
       ROUND(1.8 + 2.4 * DRIFT + 3.4 * BREACH_RISK_COUNT + U_NOISE * 1.1, 2) AS ABANDON_PCT,
       ROUND(5.5 + 3 * DRIFT + 4.5 * BREACH_RISK_COUNT + U_NOISE * 2, 1) AS AVG_HANDLE_MIN,
       CURRENT_TIMESTAMP() AS LOADED_AT
FROM measured;

-- Client document coverage per program (snapshot).
CREATE TABLE RAW.CONTROL_DOCUMENTS AS
SELECT ID AS ENTITY_ID,
       CASE CATEGORY WHEN 'Voice inbound' THEN 'SLA schedule sign-off'
                     WHEN 'Chat support' THEN 'Workforce plan approval'
                     WHEN 'Technical support' THEN 'Escalation matrix'
                     WHEN 'Back-office processing' THEN 'Data privacy checklist'
                     ELSE 'Business continuity drill record' END AS DOC_TYPE,
       1 + MOD(ABS(HASH(ID, 'phsla-req')), 4) AS REQUIRED_QTY,
       MOD(ABS(HASH(ID, 'phsla-file')), 5) AS ON_FILE_QTY,
       IFF(MOD(ABS(HASH(ID, 'phsla-file')), 5) < 1 + MOD(ABS(HASH(ID, 'phsla-req')), 4),
           MOD(ABS(HASH(ID, 'phsla-pending')), 3), 0) AS PENDING_QTY,
       CURRENT_DATE() AS SNAPSHOT_DATE
FROM RAW.PROGRAMS;
