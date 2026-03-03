# B2B SaaS Revenue & Retention Analytics System  

### Production-Style SQL Pipeline + Power BI Executive Dashboard  

---

## 1. Executive Summary  

This project builds a **production-style analytics system** to evaluate subscription growth health and sustainability for a B2B SaaS business.  

It answers the executive question:  

> **Is our growth healthy, sustainable, and efficient?**  

The system measures:

- Revenue composition (New / Expansion / Contraction / Churn)  
- Monthly Recurring Revenue (MRR) reconciliation  
- Customer retention (logo retention)  
- Gross Revenue Retention (GRR)  
- Net Revenue Retention (NRR)  
- Cohort behavior over time  
- Growth efficiency (Customer Acquisition Cost vs revenue)  

The dataset is synthetic but engineered to simulate realistic B2B SaaS behavior over 36 months.  

---

## 2. Business Model Assumptions  

- 36 months of data (Jan 2023 – Dec 2025)  
- 10,000 total customers  
- 3 subscription plans:  
  - Basic ($50)  
  - Plus ($100)  
  - Pro ($200)  
- 3% monthly churn  
- 7% monthly plan change rate  
  - 70% upgrades  
  - 30% downgrades  
- Linear growth with controlled randomness  
- Customer acquisition channels with variable CAC (Customer Acquisition Cost)  

---

## 3. Architecture Overview  

The system follows a layered architecture inspired by production analytics environments.  

Python Generator  
↓  
RAW (PostgreSQL)  
↓  
STAGING (cleaned & standardized)  
↓  
MART (star schema + KPI views)  
↓  
Power BI (semantic model + executive reporting)  

---

## 4. Data Pipeline Layers  

### RAW Layer  

Stores CSV data exactly as generated.  
No transformations.  
Source-of-truth ingestion tables.  

Tables:  
- raw.plans  
- raw.customers  
- raw.customer_month  
- raw.acquisition_cost  

---

### STAGING Layer  

Standardized and validated data.  

Adds:  
- Type enforcement  
- Basic flags (e.g., churn month indicator)  
- Clean structure for analytics  

---

### MART Layer (Analytics-Ready)  

Star schema design:  

**Dimensions**  
- mart.dim_date  
- mart.dim_customer  
- mart.dim_plan  

**Fact Table**  
- mart.fact_customer_month  
  - Grain: 1 row per customer per month  

Includes:  
- MRR  
- Previous month MRR  
- MRR delta  
- Movement classification:  
  - New  
  - Expansion  
  - Contraction  
  - Churn  
  - Flat  
  - Inactive  

---

### Analytical Views  

#### Monthly MRR Bridge  
`mart.vw_monthly_mrr_bridge`  

Reconciles:  

Beginning MRR  
+ New  
+ Expansion  
- Contraction  
- Churn  
= Ending MRR  

Includes a reconciliation check (`bridge_diff`) to ensure financial consistency.  

---

#### Monthly Retention Metrics  
`mart.vw_monthly_retention`  

Metrics:  
- Logo retention rate  
- Gross Revenue Retention (GRR)  
- Net Revenue Retention (NRR)  

Definitions:  
- GRR = (Beginning MRR - Contraction - Churn) / Beginning MRR  
- NRR = (Beginning MRR + Expansion - Contraction - Churn) / Beginning MRR  

---

## 5. Power BI Model  

- Star schema imported from MART  
- Single-direction relationships  
- Minimal DAX (measures only)  
- SQL handles heavy transformations  
- Executive-level visuals:  
  - MRR trend  
  - MRR bridge  
  - Retention KPIs  
  - Growth diagnostics  

---

## 6. Reproducibility  

The dataset is fully reproducible.  

To regenerate:  

1. Run `generate_saas_data.py`  
2. Reload CSVs into `raw` schema  
3. Execute staging scripts  
4. Rebuild mart tables and views  
5. Refresh Power BI  

The pipeline is fully rerunnable.  

---

## 7. Key Signals Demonstrated  

This project showcases:  

- Production-style layered SQL architecture  
- Star schema modeling  
- Window functions (LAG)  
- Revenue movement classification logic  
- KPI definition rigor  
- Financial reconciliation validation  
- Separation of computation vs presentation logic  
- Clean Power BI semantic modeling  

---

## 8. Repository Structure  

1_data_generation/  
    generate_saas_data.py  

2_data/  
    raw/  
    samples/  

3_sql/  
    raw/  
    staging/  
    mart/  

4_powerbi/  
    Power BI report file  

0_project_admin/  
    assumptions.md  

README.md  
LICENSE  

---

## 9. Why This Project Matters  

This is not a dashboard exercise.  

It is a full analytics system designed to reflect how subscription businesses measure:  

- Growth quality  
- Revenue durability  
- Expansion strength  
- Churn risk  
- Capital efficiency  

The architecture mirrors real-world BI environments and is intentionally built for scalability and clarity.  

*Project by [EstebanSP23](https://github.com/EstebanSP23) – Production-oriented Data Analytics Portfolio*

