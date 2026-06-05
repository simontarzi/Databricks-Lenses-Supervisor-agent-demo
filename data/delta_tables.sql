-- Supervisor Agent demo — Delta side (Unity Catalog)
-- Adjust the catalog/schema below to your workspace. Default: lenses_demo.silver
-- If your metastore uses Default Storage and CREATE CATALOG fails, create the catalog
-- in the UI (or use an existing managed catalog) and change the qualified names here.
--
-- Internally consistent: every credit_balances.customer_id exists in customers;
-- 2 customers within 10% of credit limit (C-001, C-008);
-- 3 inventory products below reorder threshold (M8 Hex Bolt x100, Torx T25 Bit Set, M10 Anchor Bolt x50).

CREATE CATALOG IF NOT EXISTS lenses_demo;
CREATE SCHEMA  IF NOT EXISTS lenses_demo.silver;

-- ============ customers ============
CREATE OR REPLACE TABLE lenses_demo.silver.customers (
  customer_id STRING, customer_name STRING, tier STRING,
  credit_limit_eur DOUBLE, account_manager STRING, country STRING
);
INSERT INTO lenses_demo.silver.customers VALUES
  ('C-001','Acme Construction GmbH','PLATINUM',80000,'Lena Brandt','DE'),
  ('C-002','Bauwelt Schneider AG','PLATINUM',95000,'Markus Vogel','CH'),
  ('C-003','Alpenmetall GmbH','GOLD',35000,'Sophie Berger','AT'),
  ('C-004','Rheinbau Handel GmbH','GOLD',28000,'Jonas Keller','DE'),
  ('C-005','Tirol Werkzeug GmbH','GOLD',22000,'Anna Huber','AT'),
  ('C-006','Helvetia Fasteners AG','SILVER',12000,'Luca Meier','CH'),
  ('C-007','Nordstahl GmbH','SILVER',9000,'Felix Wagner','DE'),
  ('C-008','Donau Schrauben GmbH','SILVER',6000,'Mara Fischer','AT'),
  ('C-009','Schwarzwald Bau GmbH','BRONZE',3500,'Tim Roth','DE'),
  ('C-010','Salzach Metall e.U.','BRONZE',2000,'Eva Klein','AT');

-- ============ inventory ============
CREATE OR REPLACE TABLE lenses_demo.silver.inventory (
  product STRING, sku STRING, stock_level INT, reorder_threshold INT,
  warehouse STRING, unit_price_eur DOUBLE
);
INSERT INTO lenses_demo.silver.inventory VALUES
  ('M8 Hex Bolt x100','BOLT-M8-100',40,50,'Warehouse-DE',24.50),          -- below threshold
  ('A2 Self-Drilling Screw x50','SCRW-A2-50',800,200,'Warehouse-AT',18.90),
  ('Torx T25 Bit Set','BIT-T25',15,30,'Warehouse-CH',31.20),               -- below threshold
  ('M6 Stainless Nut x200','NUT-M6-200',500,150,'Warehouse-DE',22.50),
  ('DIN 933 Bolt Kit','KIT-DIN933',60,40,'Warehouse-DE',89.99),
  ('M10 Anchor Bolt x50','BOLT-M10-50',25,60,'Warehouse-AT',41.00),        -- below threshold
  ('Pozidriv PZ2 Bit Set','BIT-PZ2',220,50,'Warehouse-CH',12.80),
  ('Hex Key Wrench Set','WR-HEX',140,40,'Warehouse-DE',16.40),
  ('M4 Machine Screw x500','SCRW-M4-500',900,300,'Warehouse-AT',9.90),
  ('Cable Tie 200mm x100','TIE-200-100',700,200,'Warehouse-DE',6.50),
  ('Threaded Rod M8 1m','ROD-M8-1M',300,80,'Warehouse-CH',7.20),
  ('Flange Nut M8 x100','NUT-FL-M8-100',410,120,'Warehouse-DE',11.30);

-- ============ credit_balances ============
CREATE OR REPLACE TABLE lenses_demo.silver.credit_balances (
  customer_id STRING, current_outstanding_eur DOUBLE,
  last_payment_date DATE, ytd_orders_eur DOUBLE
);
INSERT INTO lenses_demo.silver.credit_balances VALUES
  ('C-001',74000,DATE'2026-05-10',312000),  -- 92.5% of limit -> near
  ('C-002',38000,DATE'2026-05-22',410000),
  ('C-003',21000,DATE'2026-05-18',128000),
  ('C-004',8400, DATE'2026-05-29',96000),
  ('C-005',15400,DATE'2026-05-15',74000),
  ('C-006',3600, DATE'2026-05-27',41000),
  ('C-007',6300, DATE'2026-05-20',33000),
  ('C-008',5600, DATE'2026-05-08',47000),   -- 93.3% of limit -> near
  ('C-009',1400, DATE'2026-05-25',12000),
  ('C-010',1000, DATE'2026-05-30',7000);

-- ============ sanity checks ============
-- SELECT count(*) FROM lenses_demo.silver.customers;        -- 10
-- SELECT count(*) FROM lenses_demo.silver.inventory;        -- 12
-- SELECT count(*) FROM lenses_demo.silver.credit_balances;  -- 10
-- SELECT * FROM lenses_demo.silver.inventory WHERE stock_level < reorder_threshold;  -- 3 rows
-- SELECT c.customer_id, c.customer_name,
--        ROUND(b.current_outstanding_eur / c.credit_limit_eur * 100, 1) AS pct_used
-- FROM lenses_demo.silver.customers c JOIN lenses_demo.silver.credit_balances b USING (customer_id)
-- WHERE b.current_outstanding_eur / c.credit_limit_eur > 0.9;  -- C-001, C-008
