-- Generated from generator/demo_specs/aws-philippines-bpo-sla.json
-- Regenerate with: python3 generator/gen_repo_docs.py aws-philippines-bpo-sla
-- This is the schema that is actually deployed for PH_BPO_SLA.

-- PH_BPO_SLA  (Service Level Optimization & SLA Drift Detection)
-- generated from generator/demo_specs/aws-philippines-bpo-sla.json - do not hand-edit
CREATE DATABASE IF NOT EXISTS PH_BPO_SLA;
CREATE SCHEMA IF NOT EXISTS PH_BPO_SLA.RAW;
CREATE SCHEMA IF NOT EXISTS PH_BPO_SLA.CURATED;
CREATE SCHEMA IF NOT EXISTS PH_BPO_SLA.APP;
USE DATABASE PH_BPO_SLA;

-- 5 real regions; entity names carry their region so the two always agree
