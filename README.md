# SaaS Subscription Revenue & Retention Analytics (SQL + Power BI)

This project builds an analytics system to evaluate subscription growth health:
- Revenue composition (new / expansion / contraction / churn)
- Customer retention and churn
- Net revenue retention and gross revenue retention
- Cohort retention curves
- Growth efficiency (acquisition cost vs value)

**Dataset:** Synthetic, generated to simulate realistic B2B SaaS behavior over 36 months.

## Repo Structure
- /src: data generation code
- /data/raw: generated CSV inputs (source-of-truth files)
- /sql: SQL scripts (raw → staging → mart)
- /docs: KPI definitions, assumptions, diagrams