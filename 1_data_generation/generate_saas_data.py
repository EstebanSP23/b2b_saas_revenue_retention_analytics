import random
import math
from datetime import date
import pandas as pd

# ----------------------------
# Config (your locked choices)
# ----------------------------
SEED = 42
MONTHS = 36
TOTAL_CUSTOMERS = 10_000

CHURN_RATE = 0.03
PLAN_CHANGE_RATE = 0.07
UPGRADE_SHARE = 0.70  # of plan changes
DOWNGRADE_SHARE = 0.30

# Initial plan distribution for new signups (can tweak later)
INIT_PLAN_DIST = {
    "Basic": 0.60,
    "Plus": 0.30,
    "Pro": 0.10
}

PLANS = [
    {"plan_id": 1, "plan_name": "Basic", "monthly_price": 50},
    {"plan_id": 2, "plan_name": "Plus",  "monthly_price": 100},
    {"plan_id": 3, "plan_name": "Pro",   "monthly_price": 200},
]

CHANNELS = ["Paid Search", "Outbound", "Referral", "Content", "Partners"]
# Simple CAC (acquisition cost) ranges by channel (USD)
CAC_RANGES = {
    "Paid Search": (200, 600),
    "Outbound": (300, 900),
    "Referral": (50, 200),
    "Content": (80, 300),
    "Partners": (150, 500),
}

# Choose a start month (only affects dates in output)
START_YEAR = 2023
START_MONTH = 1

random.seed(SEED)

# ----------------------------
# Helpers
# ----------------------------
def month_start(year: int, month: int) -> date:
    return date(year, month, 1)

def add_months(d: date, m: int) -> date:
    y = d.year + (d.month - 1 + m) // 12
    mo = (d.month - 1 + m) % 12 + 1
    return date(y, mo, 1)

def weighted_choice(items, weights):
    r = random.random() * sum(weights)
    upto = 0.0
    for item, w in zip(items, weights):
        upto += w
        if upto >= r:
            return item
    return items[-1]

def plan_name_to_id(name: str) -> int:
    return next(p["plan_id"] for p in PLANS if p["plan_name"] == name)

def plan_id_to_price(plan_id: int) -> int:
    return next(p["monthly_price"] for p in PLANS if p["plan_id"] == plan_id)

def upgrade_plan(plan_id: int) -> int:
    # Basic -> Plus -> Pro -> Pro
    return min(plan_id + 1, 3)

def downgrade_plan(plan_id: int) -> int:
    # Pro -> Plus -> Basic -> Basic
    return max(plan_id - 1, 1)

# ----------------------------
# 1) Create the month calendar
# ----------------------------
start = month_start(START_YEAR, START_MONTH)
months = [add_months(start, i) for i in range(MONTHS)]

# ----------------------------
# 2) Generate new customers per month (linear + noise, normalized to 10k)
# ----------------------------
# Linear ramp base: 1..MONTHS (increasing)
base = [i + 1 for i in range(MONTHS)]

# Add small noise (+/- 10%)
noisy = []
for b in base:
    noise_multiplier = random.uniform(0.90, 1.10)
    noisy.append(b * noise_multiplier)

# Normalize so sum == TOTAL_CUSTOMERS
scale = TOTAL_CUSTOMERS / sum(noisy)
monthly_new = [max(0, int(round(x * scale))) for x in noisy]

# Fix rounding drift to hit exactly TOTAL_CUSTOMERS
diff = TOTAL_CUSTOMERS - sum(monthly_new)
# Distribute +/- 1 across months to correct total
idxs = list(range(MONTHS))
random.shuffle(idxs)
for i in range(abs(diff)):
    monthly_new[idxs[i % MONTHS]] += 1 if diff > 0 else -1

assert sum(monthly_new) == TOTAL_CUSTOMERS

# ----------------------------
# 3) Generate plans.csv
# ----------------------------
plans_df = pd.DataFrame(PLANS)

# ----------------------------
# 4) Generate customers.csv + acquisition_cost.csv
# ----------------------------
customers = []
acq_cost = []

plan_names = list(INIT_PLAN_DIST.keys())
plan_weights = list(INIT_PLAN_DIST.values())

customer_id = 1
for m_idx, m_date in enumerate(months):
    n_new = monthly_new[m_idx]
    for _ in range(n_new):
        channel = random.choice(CHANNELS)
        init_plan = weighted_choice(plan_names, plan_weights)
        customers.append({
            "customer_id": customer_id,
            "signup_month": m_date.isoformat(),
            "acquisition_channel": channel,
            "initial_plan_id": plan_name_to_id(init_plan),
        })
        lo, hi = CAC_RANGES[channel]
        acq_cost.append({
            "customer_id": customer_id,
            "acquisition_channel": channel,
            "signup_month": m_date.isoformat(),
            "cac": round(random.uniform(lo, hi), 2),
        })
        customer_id += 1

customers_df = pd.DataFrame(customers)
acq_cost_df = pd.DataFrame(acq_cost)

# ----------------------------
# 5) Simulate customer_month.csv (main fact-like output)
# ----------------------------
# Track state: active customers with current plan_id
active = {}  # customer_id -> plan_id

# Pre-index new customers by month for quick activation
new_by_month = {}
for row in customers:
    new_by_month.setdefault(row["signup_month"], []).append((row["customer_id"], row["initial_plan_id"]))

customer_month_rows = []

for m_date in months:
    m_key = m_date.isoformat()

    # Add new customers for this month (they become active immediately)
    for cid, plan_id in new_by_month.get(m_key, []):
        active[cid] = plan_id

    # Simulate churn + plan changes for current active customers
    # (We iterate over a list copy because we may remove churned customers.)
    active_ids = list(active.keys())

    for cid in active_ids:
        # 1) Churn first
        if random.random() < CHURN_RATE:
            # Record month as churned (MRR=0), then remove from active
            customer_month_rows.append({
                "customer_id": cid,
                "month": m_key,
                "plan_id": None,
                "mrr": 0
            })
            del active[cid]
            continue

        # 2) Plan change second
        plan_id = active[cid]
        if random.random() < PLAN_CHANGE_RATE:
            if random.random() < UPGRADE_SHARE:
                plan_id = upgrade_plan(plan_id)
            else:
                plan_id = downgrade_plan(plan_id)
            active[cid] = plan_id

        # 3) Record active month
        customer_month_rows.append({
            "customer_id": cid,
            "month": m_key,
            "plan_id": plan_id,
            "mrr": plan_id_to_price(plan_id)
        })

customer_month_df = pd.DataFrame(customer_month_rows)
customer_month_df["plan_id"] = customer_month_df["plan_id"].astype("Int64")

# ----------------------------
# 6) Write outputs
# ----------------------------
import os

# Define output folder relative to project root
BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUTPUT_DIR = os.path.join(BASE_DIR, "2_data","raw")

os.makedirs(OUTPUT_DIR, exist_ok=True)

plans_df.to_csv(os.path.join(OUTPUT_DIR, "plans.csv"), index=False)
customers_df.to_csv(os.path.join(OUTPUT_DIR, "customers.csv"), index=False)
customer_month_df.to_csv(os.path.join(OUTPUT_DIR, "customer_month.csv"), index=False)
acq_cost_df.to_csv(os.path.join(OUTPUT_DIR, "acquisition_cost.csv"), index=False)

print("Generated files:")
print("- plans.csv")
print("- customers.csv")
print("- customer_month.csv")
print("- acquisition_cost.csv")
print("Rows in customer_month:", len(customer_month_df))

# Quick sanity analytics
monthly_summary = (
    customer_month_df
    .groupby("month")
    .agg(
        active_customers=("customer_id", lambda s: s[customer_month_df.loc[s.index, "mrr"] > 0].nunique()),
        total_mrr=("mrr", "sum")
    )
    .reset_index()
)

print("\nMonthly summary (first 5 rows):")
print(monthly_summary.head())

print("\nMonthly summary (last 5 rows):")
print(monthly_summary.tail())

print("\nMonthly summary (last row):")
print(monthly_summary.tail(1))