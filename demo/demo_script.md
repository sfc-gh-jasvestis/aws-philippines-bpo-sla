# Service Level Optimization & SLA Drift Detection

**Philippines - BPO & IT Services**
Use case: Service Level Optimization

> Philippine BPOs manage 200+ SLA metrics across dozens of clients — Snowflake detects SLA drift in real-time with anomaly detection, predicts breaches before they happen, and auto-triggers corrective workflows.

## Why Snowflake

Snowflake ingests real-time operational metrics via Kinesis, detects SLA drift with ML.ANOMALY_DETECTION, predicts breaches, and triggers automated remediation via EventBridge-integrated Task Graphs — proactive, not reactive

- **ML.ANOMALY_DETECTION for SLA drift** - Only demo using anomaly detection for operational SLA metrics — not financial or IoT
- **EventBridge → Task Graph remediation** - Automated corrective action pipeline triggered by ML detection
- **15-minute interval real-time data** - Sub-hourly granularity for contact center performance monitoring
- **Penalty exposure projection** - Financial impact quantified in pesos before breach occurs
- **CloudWatch alarm classification** - AI_CLASSIFY on infrastructure alarms linking infra issues to SLA impact
- **Philippine BPO multi-client SLA context** - 200+ metrics, 42 clients, penalty clauses — realistic enterprise BPO complexity

## What is deployed

| | |
|---|---|
| Database | `PH_BPO_SLA` |
| Service | `PH_BPO_SLA_APP` |
| Compute pool | `SEA_DEMOS_PHILIPPINES_POOL` |
| Dimension table | `RAW.CLIENT_CONTRACTS` (20 rows) |
| Fact table | `RAW.INTERVAL_PERFORMANCE` (250,000 rows, 90 days) |
| Curated layer | `CURATED.PERFORMANCE_SUMMARY`, `CURATED.TREND_ANALYSIS`, `CURATED.KPI_SUMMARY` |
| Currency | PHP (₱) |

Regions in play: Metro Manila, Cebu, Davao, Pampanga, Iloilo
Segments: Answer Speed, Resolution Time, Quality Score, Abandonment

Dynamic tables are created suspended and refreshed on demand:

```bash
./refresh_demo_data.sh PH_BPO_SLA
```

## KPI cards

Every card below is served live from `CURATED.KPI_SUMMARY`. The app keeps the
original literal as a fallback, so it still renders if Snowflake is unreachable.

| Card | Value | Backed by |
|---|---|---|
| SLA Achievement | `97.2%` | average per event |
| Penalties Incurred | `₱4.8M` | total across Client Contracts |
| Tickets Resolved | `847K` | total across Client Contracts |
| Active SLAs | `124` | total across Client Contracts |
| Breaches (MTD) | `42` | total across Client Contracts |
| Avg Resolution | `2.4 hrs` | average per event |
| Escalation Rate | `8%` | average per event |


## Demo flow

1. Executive Cockpit
2. Drift Detection
3. Staffing & Remediation
4. Ask AI
5. Architecture & Data

## Talking points

- **200+** - SLA metrics monitored in real-time
- **₱34M** - projected penalty exposure this quarter
- **8 accounts** - showing anomalous SLA drift
- **72 hours** - advance warning before FinServ AHT breach
- **127 FTEs** - staffing gap identified across graveyard shifts
- **₱8.5M saved** - single remediation preventing FinServ penalty

## Business impact

- SLA penalties cost Philippine BPOs $200-500M annually across the industry (Everest Group)
- Proactive SLA management reduces penalty payouts by 40-60% (Gartner)
- Real-time anomaly detection identifies service degradation 3-5x faster than threshold alerts (McKinsey Digital)

---
Generated from `generator/demo_specs/aws-philippines-bpo-sla.json`. Do not hand-edit: run
`python3 generator/gen_repo_docs.py aws-philippines-bpo-sla` instead.
