# Philippines BPO Client SLA Monitor

**Philippines - BPO Client Programs**
Use case: Client SLA breaches, contact-centre incidents, QA calibration and client document controls

> Client SLA monitoring for 40 client programs of a fictional Philippine BPO served from 5 cities: dynamic tables, a holdout-evaluated SLA-breach classifier, an incident-volume forecast and grounded AI answers.

## Why Snowflake

- **Dynamic tables** reconcile contacts handled, incidents, SLA-breach incidents, client penalty notices and QA calibration compliance from RAW program data, with checks in `run_core.py`
- **SLA-breach classification** gives a holdout-evaluated next-7-day probability per program
- **Incident forecast** projects 14 days of incident volume across all programs with prediction intervals, for workforce planning
- **Grounded AI**: the Cortex Agent (Analyst over a semantic view, plus Search over SOPs) shows its SQL and SOP citations
- **Live contacts**: a native simulator (Snowflake only) or Firehose, S3 and Snowpipe (AWS build), then an alert and email

## What is built

| | |
|---|---|
| Dimension table | `RAW.PROGRAMS` (40 rows) |
| Fact table | `RAW.PROGRAM_DAILY` (3,600 program-days, 90 days) |
| Curated layer | `CURATED.KPI_SUMMARY`, `PERFORMANCE_SUMMARY`, `INCIDENT_SUMMARY`, `TREND_ANALYSIS` |
| ML | `ML.BREACH_RISK_SCORES`, `ML.BREACH_RISK_HOLDOUT_METRICS`, `ML.INCIDENT_FORECAST`, `ML.ABANDON_ANOMALIES` |

Cities: Taguig City, Pasig City, Cebu City, Davao City, Bacolod City (PHP).
Channels: Voice inbound, Chat support, Technical support, Back-office processing, Email support.

## KPI cards (live from `CURATED.KPI_SUMMARY`; no fallback values)

| Card | Value from the seeded data |
|---|---|
| Incident-Free Contact Rate | 99.99% |
| Incidents Raised | 594 |
| SLA-Breach Incidents | 171 |
| Incident Breach Rate | 28.8% |
| Penalty Notices | 70 |
| Billable Value (PHP M) | 342 |
| Contacts Handled | 5,960,005 |
| QA Calibration Compliance | 72.2% |
| Programs Monitored | 40 |
| Client Document Coverage | 60.4% |
| Client Documents Pending | 28 |

Values are synthetic. A rebuild reproduces them because the data is HASH-seeded; dates are relative to the build day.

## Demo flow

1. Executive Cockpit: KPIs, daily incidents against SLA-breach incidents, incidents and breaches by incident type, program table
2. Predictive: holdout metrics, risk bands, 14-day incident forecast, abandon-rate anomalies
3. Quality & Contracts: QA calibration compliance, client document coverage and pending documents, calibration compliance against SLA breaches, then generate the action memo
4. Live Contacts: run `CALL APP.SIMULATE_CONTACTS(20)` (Snowflake only) or `python aws/publish_contacts.py --count 20` (AWS build). Then run `EXECUTE ALERT APP.LIVE_INCIDENT_ALERT` and show the alert log and email.
5. Ask AI: the Cortex Agent answers metric questions through the semantic view and cites SOPs from Cortex Search. The SQL is shown.
6. QuickSight (AWS build): the same Snowflake tables through DIRECT_QUERY
7. Architecture: both builds side by side

## Talking points

- 99.99% of contacts are untouched by an incident; the 594 incidents are where service delivery time goes, and 28.8% of them cost the program its daily service level.
- Staffing shortfalls produce the most SLA-breach incidents (61 of 157). Area power interruptions hit every program in a city at once and always resolve on backup power.
- The risk model is evaluated on a time-based holdout: precision 0.38 and recall 0.22 at 0.5, against a 0.242 base rate. Present it as triage, not a verdict.
- Area power interruptions are excluded from model training, because they are not program-driven.

## Business impact

Use only the sourced references in `README.md` (Business Impact).
