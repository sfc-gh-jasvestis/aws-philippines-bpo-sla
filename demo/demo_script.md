# Demo Script: Service Level Optimization & SLA Drift Detection
## ~4-Minute Recorded Walkthrough
**Format**: Screen recording with voiceover
**Target**: Customer meeting / booth loop / social share
**Narrative**: "Snowflake ingests real-time operational metrics via Kinesis, detects SLA drift with ML.ANOMALY_DETECTION, predicts breaches, and triggers automated remediation via EventBridge-integrated Task Graphs — proactive, not reactive"
**Demo Mode**: Open app with `?demo=true` for presenter notes

---

## Two Personas

| Persona | Role | Tool | What they care about |
|---|---|---|---|
| **Eduardo Jose Gonzales** | SVP Operations | React App (SPCS) | SLA compliance across clients, penalty exposure, operational efficiency, staffing gaps |
| **Angelica Mae Dela Cruz** | Service Delivery Manager | Amazon QuickSight | Real-time queue management, AHT drift, abandon rates, interval-level performance |

---

## What's Built

| Layer | Component | Detail |
|---|---|---|
| **RAW** | 6 tables | CLIENT_CONTRACTS (42), SLA_METRICS (200), INTERVAL_PERFORMANCE (1200000), STAFFING_SCHEDULES (95000), PENALTY_HISTORY (380), CLOUDWATCH_ALARMS (15000) |
| **CURATED** | 4 Dynamic Tables | SLA_HEALTH_REALTIME, PENALTY_EXPOSURE, STAFFING_GAP_ANALYSIS, SLA_TIMESERIES |
| **ML** | ML.ANOMALY_DETECTION + ML.FORECAST | Forecasting + anomaly detection |
| **AI** | COMPLETE, AI_CLASSIFY | Classification + extraction |
| **Search** | Cortex Search | 42 documents indexed |
| **Agent** | SLA_OPERATIONS_AGENT | Semantic View + Search tools |


---

## The Story

A top-10 Philippine BPO manages 200+ SLA metrics for 42 enterprise clients with combined contract value of ₱4.2 billion. Every quarter, SLA penalties cost ₱15-40M — but the real damage is client churn when accounts lose confidence. Traditional monitoring detects breaches after they happen. Snowflake detects drift days before breach, predicts impact, and auto-triggers remediation.

---

## Script

### [0:00–0:45] EXECUTIVE COCKPIT

**Show**: Executive Cockpit tab

> "Two hundred SLA metrics monitored in real-time across 42 client accounts."

**Action**: Point at 200 SLA metrics KPI

### [0:45–1:30] DRIFT DETECTION

**Show**: Drift Detection tab

> "ML.ANOMALY_DETECTION flagged FinServ account AHT drifting up — 4.2 min vs 3.5 min target."

**Action**: Show AHT timeseries with anomaly markers

### [1:30–2:15] STAFFING & REMEDIATION

**Show**: Staffing & Remediation tab

> "Staffing gap analysis shows 127 FTEs needed across 3 sites for this week."

**Action**: Show staffing heatmap by shift and site

### [2:15–3:00] ASK AI

**Show**: Ask AI tab

> "Eduardo asks: 'What's our total penalty exposure for Q4?'"

**Action**: Type: 'Total penalty exposure Q4?'

### [3:00–3:45] ARCHITECTURE & DATA

**Show**: Architecture & Data tab

> "Kinesis → Snowpipe Streaming → Dynamic Tables → ML.ANOMALY_DETECTION → Task Graphs → remediation."

**Action**: Walk through architecture diagram


---

## Key Demo Differentiators

1. **ML.ANOMALY_DETECTION for SLA drift** — Only demo using anomaly detection for operational SLA metrics — not financial or IoT
2. **EventBridge → Task Graph remediation** — Automated corrective action pipeline triggered by ML detection
3. **15-minute interval real-time data** — Sub-hourly granularity for contact center performance monitoring
4. **Penalty exposure projection** — Financial impact quantified in pesos before breach occurs
5. **CloudWatch alarm classification** — AI_CLASSIFY on infrastructure alarms linking infra issues to SLA impact
6. **Philippine BPO multi-client SLA context** — 200+ metrics, 42 clients, penalty clauses — realistic enterprise BPO complexity


---

## Demo Prep Checklist

### Data Verification
- [ ] `SELECT COUNT(*) FROM SLA_OPERATIONS.RAW.INTERVAL_PERFORMANCE` → 1200000
- [ ] `SELECT COUNT(*) FROM SLA_OPERATIONS.RAW.CLOUDWATCH_ALARMS` → 15000
- [ ] `SELECT COUNT(DISTINCT CLIENT_METRIC_ID) FROM SLA_OPERATIONS.CURATED.SLA_HEALTH_REALTIME WHERE STATUS = 'DRIFTING'` → >=8

### ML Model Verification
- [ ] `SELECT COUNT(*) FROM SLA_OPERATIONS.ML.SLA_ANOMALY_RESULTS WHERE IS_ANOMALY = TRUE` → >0
- [ ] `SELECT COUNT(*) FROM SLA_OPERATIONS.ML.SLA_BREACH_FORECAST_RESULTS` → >0

### AI/Agent Verification
- [ ] `SELECT COUNT(*) FROM SLA_OPERATIONS.AI.ALARM_CLASSIFICATION` → 15000

