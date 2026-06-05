# The demo — 5 rounds

Reordered as grounded → fresh → multi-hop → topic audit → action. Have prompts ready to paste; don't type them live. Re-run the Kafka loader shortly before the demo so the "last hour" window is fresh.

## Round 1 — Grounded only (Genie)
> "What's Acme Construction's credit limit, and how much have they ordered year to date?"

Expect: credit limit **€80,000**, YTD **€312,000** (and €74,000 outstanding). Talk track: *"Genie translated my question into SQL over governed Delta tables."*

## Round 2 — Fresh only (Lenses MCP)
> "Using lenses_mcp, what are the last 5 orders that landed on orders-v2, and which customers placed them?"

Expect: recent messages from `orders-v2`. Talk track: *"I didn't write a Kafka query — Lenses MCP did."*

## Round 3 — Multi-hop, both sources (centerpiece)
First, fire the live "wow" order (so there's a juicy at-risk order in the last hour):
```bash
python3 data/gen_orders.py --wow | <your-kafka-producer> --topic orders-v2
```
Then ask:
> "Of the orders on orders-v2 in the last hour, which are from customers who are within 10% of their credit limit?"

Expect: the agent calls Lenses for last-hour orders, Genie for credit limits/balances, joins on `customer_id`, and flags orders from **C-001 (Acme)** and **C-008 (Donau Schrauben)**. Talk track: *"This is the part you can't do with a single tool — the supervisor picked the right source for each slice and joined them in its own reasoning. No Spark job, no glue code."* **Capture the tool-call decomposition + final answer (blog images).**

## Round 4 — Topic audit (Lenses Kafka agent skill)
> Run a topic-audit workflow on `orders-v2` (schema health, throughput, anomalies) using the Lenses Kafka agent skills.

A defined, repeatable workflow rather than open-ended judgment.

## Round 5 — Action close
> "Draft a short email to the account manager for the highest-risk order you found."

Expect: an email with the right customer, order detail, and risk reasoning. Segues into the governance story (private data + untrusted content + external action = the lethal trifecta; Lenses RBAC/PII/audit on Kafka, Unity Catalog on Delta).

## Pre-flight checklist (~30 min before)
- [ ] Lenses healthy; MCP reachable by Databricks
- [ ] `orders-v2` reloaded — 30+ messages, 6 in the last hour
- [ ] Genie answers the sample questions correctly
- [ ] Playground session has **both** tools attached; system prompt set with your environment name
- [ ] "Wow" order one-liner ready in your terminal
- [ ] Backup screenshots of each round
