#!/usr/bin/env python3
"""Generate internally-consistent B2B hardware order events for the orders topic.
Customer IDs match the Delta `customers` table (C-001..C-010); products match `inventory`.
Timestamps are relative to NOW so 'last hour' queries always work. Stdlib only.

Usage:
  python3 gen_orders.py            # 30 orders, JSON lines (6 within the last hour)
  python3 gen_orders.py --wow      # single large "wow" order from C-001, timestamped now
"""
import json, random, sys
from datetime import datetime, timedelta, timezone

PRODUCTS = [
    "M8 Hex Bolt x100", "A2 Self-Drilling Screw x50", "Torx T25 Bit Set",
    "M6 Stainless Nut x200", "DIN 933 Bolt Kit", "M10 Anchor Bolt x50",
    "Pozidriv PZ2 Bit Set", "Hex Key Wrench Set", "M4 Machine Screw x500",
    "Cable Tie 200mm x100", "Threaded Rod M8 1m", "Flange Nut M8 x100",
]
CUSTOMERS = (["C-001"] * 5 + ["C-002"] * 4 +
             ["C-003", "C-004", "C-005", "C-006", "C-007", "C-008", "C-009", "C-010"])

def iso(dt):
    return dt.astimezone(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")

def amount():
    return round(random.choice([random.uniform(10, 300)] * 6 +
                               [random.uniform(300, 1000)] * 2 +
                               [random.uniform(1000, 3000)]), 2)

def main():
    random.seed(42)
    now = datetime.now(timezone.utc)
    if "--wow" in sys.argv:
        print(json.dumps({"order_id": "ORD-099", "customer_id": "C-001",
                          "product": "M10 Anchor Bolt x50", "amount": 2700.00,
                          "currency": "EUR", "timestamp": iso(now)}))
        return

    events = [(now - timedelta(minutes=random.randint(2, 55)), True) for _ in range(6)]
    events += [(now - timedelta(minutes=random.randint(70, 1440)), False) for _ in range(24)]
    events.sort(key=lambda x: x[0])

    for i, (ts, recent) in enumerate(events, start=1):
        if recent and i == len(events) - 2:
            cust, prod, amt = "C-001", "M10 Anchor Bolt x50", round(random.uniform(2000, 2800), 2)
        else:
            cust, prod, amt = random.choice(CUSTOMERS), random.choice(PRODUCTS), amount()
        print(json.dumps({"order_id": f"ORD-{i:03d}", "customer_id": cust, "product": prod,
                          "amount": amt, "currency": "EUR", "timestamp": iso(ts)}))

if __name__ == "__main__":
    main()
