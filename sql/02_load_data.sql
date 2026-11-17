-- =============================================================================
-- 02_load_data.sql
-- Loads the CSV files. Run from the repository root:
--     mysql --local-infile=1 -u root -p < sql/00_run_all.sql
-- Skills: LOAD DATA, handling empty values (NULLIF), load order for foreign keys
-- =============================================================================
USE inventory_basics;

LOAD DATA LOCAL INFILE 'data/warehouses.csv' INTO TABLE warehouses
    CHARACTER SET utf8mb4 FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"' IGNORE 1 LINES;

LOAD DATA LOCAL INFILE 'data/suppliers.csv' INTO TABLE suppliers
    CHARACTER SET utf8mb4 FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"' IGNORE 1 LINES;

LOAD DATA LOCAL INFILE 'data/products.csv' INTO TABLE products
    CHARACTER SET utf8mb4 FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"' IGNORE 1 LINES;

LOAD DATA LOCAL INFILE 'data/inventory.csv' INTO TABLE inventory
    CHARACTER SET utf8mb4 FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"' IGNORE 1 LINES;

-- received_date is empty for open and cancelled orders -> store NULL
LOAD DATA LOCAL INFILE 'data/purchase_orders.csv' INTO TABLE purchase_orders
    CHARACTER SET utf8mb4 FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"' IGNORE 1 LINES
    (po_id, supplier_id, warehouse_id, order_date, expected_date, @received_date, status)
    SET received_date = NULLIF(@received_date, '');

LOAD DATA LOCAL INFILE 'data/purchase_order_lines.csv' INTO TABLE purchase_order_lines
    CHARACTER SET utf8mb4 FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"' IGNORE 1 LINES;

-- Quick check: row count per table
SELECT 'warehouses' AS table_name, COUNT(*) AS row_count FROM warehouses
UNION ALL SELECT 'suppliers',            COUNT(*) FROM suppliers
UNION ALL SELECT 'products',             COUNT(*) FROM products
UNION ALL SELECT 'inventory',            COUNT(*) FROM inventory
UNION ALL SELECT 'purchase_orders',      COUNT(*) FROM purchase_orders
UNION ALL SELECT 'purchase_order_lines', COUNT(*) FROM purchase_order_lines;
