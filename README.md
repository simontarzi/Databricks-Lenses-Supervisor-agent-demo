# Supervisor agent across Kafka and the lakehouse — demo kit

Reproduce the demo from the blog *"One question, two data realities: supervisor agents across Kafka and the lakehouse."*

A single **supervisor agent** in Databricks AI Playground answers questions that span **two data realities**:
- **fresh context** — live order events in **Kafka**, exposed via a **Lenses MCP server**
- **grounded context** — customer credit / inventory / history in **Delta** tables, exposed via a **Databricks Genie space**

The wow moment is a multi-hop question that needs both at once (e.g. *"of the orders in the last hour, which are from customers within 10% of their credit limit?"*).

> **Scope:** This kit assumes you **already have Lenses** running with its MCP server and a registered environment, and that the Lenses MCP server is reachable by Databricks. Standing up Lenses itself is **out of scope**. Everything else — datasets, Genie config, the agent system prompt, and the demo script — is here.

## Prerequisites
- A **Lenses** instance (6.2+) with the **MCP server** enabled and a registered **environment** (note its name — e.g. `demo`).
- A **Databricks** workspace with **Unity Catalog** + **Genie** + **AI Playground**, on a tool-calling model (e.g. `claude-sonnet-4-6`).
- The Lenses MCP server **registered as a Unity Catalog HTTP connection** (Is MCP connection, **OAuth** auth). MCP is OAuth/DCR-only — static bearer tokens are rejected.
- Access to your Lenses environment's Kafka to create a topic and produce messages.

## Repo layout
```
data/
  delta_tables.sql     # 3 Delta tables (customers, inventory, credit_balances), internally consistent
  gen_orders.py        # generates Kafka order events (timestamps relative to now)
  load_kafka.sh        # example: create topic + produce the events
genie/
  genie_space_config.md  # tables + sample questions + instructions for the Genie space
agent/
  system_prompt.md     # supervisor system prompt (routing rules for both tools)
demo/
  demo_script.md       # the 5-round demo + talk track + the live "wow" order
diagrams/
  supervisor_architecture.drawio  # architecture diagram (open in draw.io / import to Lucidchart)
```

## Set these placeholders to your values
| Placeholder | Meaning | Example |
|---|---|---|
| `<CATALOG>.<SCHEMA>` | Where the Delta tables live | `lenses_demo.silver` |
| `<LENSES_ENVIRONMENT>` | Your Lenses environment name | `demo` |
| `orders-v2` | Kafka topic for orders | `orders-v2` |

## Steps

### 1. Load the Delta tables
Open `data/delta_tables.sql`, adjust the catalog/schema at the top if needed, and run it in a SQL editor or notebook. Verify: 10 customers, 12 inventory rows, 10 credit_balances; 3 products below reorder threshold; 2 customers within 10% of their credit limit.

> **Gotcha:** if your metastore uses **Default Storage**, `CREATE CATALOG` may fail — create the catalog in the UI, or put the schema inside an existing managed catalog and adjust the names.

### 2. Load the Kafka demo data
Generate and produce ~30 order events (6 within the last hour) into your topic. `gen_orders.py` needs only Python stdlib.
```bash
# pipe generated JSON into any Kafka producer; example with kafka-console-producer:
python3 data/gen_orders.py | kafka-console-producer --bootstrap-server <BOOTSTRAP> --topic orders-v2
```
See `data/load_kafka.sh` for a ready-made example (incl. a docker-exec variant and the live "wow" order). Re-run before any live demo so the "last hour" window is fresh.

### 3. Build the Genie space
Follow `genie/genie_space_config.md` — add the three tables, the sample questions, and the instructions. Test the sample questions until Genie answers them correctly. (Curation matters: without the instructions, Genie won't map "YTD orders" to `ytd_orders_eur`.)

### 4. Attach both tools in AI Playground
- Confirm the **Lenses MCP** UC connection is healthy and authorize it (OAuth U2M consent) on first use.
- In one Playground session, attach **both** the **Genie space** and the **Lenses MCP** tool.
- **Remove the Python/code-exec tool** if the workspace auto-adds it (`system.ai.python_exec`) — not needed, and it errors where it isn't provisioned.

### 5. Set the supervisor system prompt
Paste `agent/system_prompt.md` into the Playground system-prompt field. **Set your `<LENSES_ENVIRONMENT>` name** — Lenses MCP tools require an `environment` parameter; the wrong value returns 404 ("Environment not found").

### 6. Run the demo
Follow `demo/demo_script.md` — 5 rounds (grounded → fresh → multi-hop → topic audit → action), with the live "wow" order and talk track.

## Gotchas worth knowing (learned the hard way)
- **MCP is OAuth/DCR-only** — don't use static bearer tokens on the UC connection.
- **Lenses MCP tools need the `environment` name** — set it in the system prompt.
- **Genie needs curation** — add table/column instructions or it won't find the right fields.
- **Drop `system.ai.python_exec`** from the Playground tools if it auto-attaches.
- **Default Storage** can block `CREATE CATALOG` — use an existing catalog.
