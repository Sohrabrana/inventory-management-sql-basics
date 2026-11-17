-- =============================================================================
-- 03_insert_update_delete.sql
-- Changing data safely inside a transaction. Everything is rolled back at the
-- end, so the dataset stays unchanged for the analysis.
-- Skills: START TRANSACTION, INSERT, UPDATE, DELETE, ROLLBACK
-- =============================================================================
USE inventory_basics;

START TRANSACTION;

-- INSERT: a new supplier and a new product from that supplier
INSERT INTO suppliers (supplier_id, supplier_name, country, city, main_category, payment_terms_days)
VALUES (11, 'Lambda Eco Paper', 'Germany', 'Leipzig', 'Paper & Printing', 30);

INSERT INTO products (product_id, sku, product_name, category, supplier_id, unit_cost_eur, list_price_eur)
VALUES (61, 'SKU-0061', 'Recycled Copy Paper A3 (500 sheets)', 'Paper & Printing', 11, 6.10, 8.90);

SELECT product_id, product_name, supplier_id FROM products WHERE product_id = 61;

-- UPDATE: supplier raises prices by 5% for the Breakroom category
UPDATE products
SET unit_cost_eur = ROUND(unit_cost_eur * 1.05, 2)
WHERE category = 'Breakroom';

SELECT product_name, unit_cost_eur FROM products WHERE category = 'Breakroom' ORDER BY product_id LIMIT 3;

-- DELETE: remove the test product again
DELETE FROM products WHERE product_id = 61;

-- Undo everything above
ROLLBACK;

-- Check: the new supplier no longer exists after the rollback
SELECT COUNT(*) AS suppliers_after_rollback FROM suppliers;
