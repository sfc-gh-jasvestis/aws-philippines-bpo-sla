-- ============================================================================
-- Service Level Optimization & SLA Drift Detection
-- Philippine BPOs manage 200+ SLA metrics across dozens of clients — Snowflake detects SLA drift in real-time with anomaly detection, predicts breaches before they happen, and auto-triggers corrective workflows.
-- ============================================================================
USE ROLE ACCOUNTADMIN;
CREATE DATABASE IF NOT EXISTS SLA_OPERATIONS;
CREATE WAREHOUSE IF NOT EXISTS SLA_WH WAREHOUSE_SIZE = 'MEDIUM' AUTO_SUSPEND = 120 AUTO_RESUME = TRUE;
USE DATABASE SLA_OPERATIONS;
CREATE SCHEMA IF NOT EXISTS RAW;
CREATE SCHEMA IF NOT EXISTS CURATED;
CREATE SCHEMA IF NOT EXISTS ML;
CREATE SCHEMA IF NOT EXISTS AI;
CREATE SCHEMA IF NOT EXISTS SEARCH;
CREATE SCHEMA IF NOT EXISTS APP;

USE WAREHOUSE SLA_WH;
