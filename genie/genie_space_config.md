# Genie space configuration

Create a Genie space in Databricks with the following. Replace `<CATALOG>.<SCHEMA>` with where you loaded the Delta tables (default `lenses_demo.silver`).

## Name
`B2B Hardware Operations`

## Description
Live operations Q&A for the hardware-distribution demo. Combines customer credit, inventory, and historical orders.

## Tables
- `<CATALOG>.<SCHEMA>.customers`
- `<CATALOG>.<SCHEMA>.inventory`
- `<CATALOG>.<SCHEMA>.credit_balances`

## Sample questions (prime the agent)
- What's the credit limit and current balance for Acme Construction?
- What is Acme Construction's credit limit and year-to-date order total?
- Which products are below their reorder threshold?
- List customers who are within 10% of their credit limit.
- What is the YTD order total for our top 3 customers by tier?

## Instructions (paste into the Genie "Instructions" panel)
> Customer IDs are C-NNN. There is **no separate orders or transactions table** — order and balance figures live in `credit_balances`, joined to `customers` on `customer_id`:
> - **Year-to-date order total** for a customer = `credit_balances.ytd_orders_eur`.
> - **Current balance / outstanding** = `credit_balances.current_outstanding_eur`.
> - **Credit limit** = `customers.credit_limit_eur`; **credit utilization** = current_outstanding_eur / credit_limit_eur.
> A customer is "within 10% of their credit limit" when utilization >= 0.90.
> `inventory.product` matches the product names in the real-time order stream; **stockout risk** = stock_level < reorder_threshold.
> Tier order: PLATINUM > GOLD > SILVER > BRONZE.

## Expected answers (for validation)
- Below reorder threshold: **M8 Hex Bolt x100, Torx T25 Bit Set, M10 Anchor Bolt x50**
- Within 10% of credit limit: **C-001 (Acme Construction, 92.5%)** and **C-008 (Donau Schrauben, 93.3%)**
- Acme Construction: credit limit **€80,000**, YTD **€312,000**, outstanding **€74,000**

> Curation matters: without the instructions above, Genie won't map "YTD orders" to `ytd_orders_eur` and will report the data as missing.
