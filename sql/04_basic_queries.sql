-- =============================================================================
-- 04_basic_queries.sql
-- 16 business questions from the purchasing and warehouse teams.
-- Each query lists the SQL skill it practises.
-- Snapshot date for "today": 31 Dec 2025.
-- =============================================================================
USE inventory_basics;


-- Q1. Which packaging products do we buy, from the cheapest to the most expensive?
-- Skills: SELECT, WHERE, ORDER BY
SELECT sku, product_name, unit_cost_eur, list_price_eur
FROM products
WHERE category = 'Packaging'
ORDER BY unit_cost_eur;


-- Q2. What are our 10 most expensive products to buy?
-- Skills: ORDER BY ... DESC, LIMIT
SELECT product_name, category, unit_cost_eur
FROM products
ORDER BY unit_cost_eur DESC
LIMIT 10;


-- Q3. How many suppliers do we have in each country?
-- Skills: COUNT, GROUP BY
SELECT country, COUNT(*) AS suppliers
FROM suppliers
GROUP BY country
ORDER BY suppliers DESC, country;


-- Q4. Which paper products cost between 5 and 30 EUR?
-- Skills: LIKE, BETWEEN, AND
SELECT product_name, unit_cost_eur
FROM products
WHERE product_name LIKE '%Paper%'
  AND unit_cost_eur BETWEEN 5 AND 30
ORDER BY unit_cost_eur;


-- Q5. What is our stock worth in each warehouse (at purchase cost)?
-- Skills: INNER JOIN, SUM, calculated column, GROUP BY
SELECT w.warehouse_name,
       COUNT(*)                                   AS stocked_items,
       SUM(i.on_hand_qty)                         AS units_on_hand,
       ROUND(SUM(i.on_hand_qty * p.unit_cost_eur)) AS stock_value_eur
FROM inventory  i
JOIN warehouses w ON w.warehouse_id = i.warehouse_id
JOIN products   p ON p.product_id   = i.product_id
GROUP BY w.warehouse_name
ORDER BY stock_value_eur DESC;


-- Q6. How much stock value is tied up in each product category?
-- Skills: SUM, ROUND, percentage of a total with a subquery
SELECT p.category,
       ROUND(SUM(i.on_hand_qty * p.unit_cost_eur)) AS stock_value_eur,
       ROUND(100 * SUM(i.on_hand_qty * p.unit_cost_eur)
             / (SELECT SUM(i2.on_hand_qty * p2.unit_cost_eur)
                FROM inventory i2 JOIN products p2 ON p2.product_id = i2.product_id), 1) AS share_pct
FROM inventory i
JOIN products  p ON p.product_id = i.product_id
GROUP BY p.category
ORDER BY stock_value_eur DESC;


-- Q7. Which items need attention? Classify every stock position.
-- Skills: CASE
SELECT stock_status,
       COUNT(*) AS items
FROM (
    SELECT CASE
               WHEN on_hand_qty = 0              THEN '1 Out of stock'
               WHEN on_hand_qty < reorder_point  THEN '2 Below reorder point'
               WHEN on_hand_qty > max_stock      THEN '4 Overstock'
               ELSE '3 OK'
           END AS stock_status
    FROM inventory
) AS classified
GROUP BY stock_status
ORDER BY stock_status;


-- Q8. Reorder list: what should each warehouse order today, and from whom?
-- Skills: JOIN across 4 tables, WHERE, calculated columns
SELECT w.warehouse_name,
       p.sku,
       p.product_name,
       s.supplier_name,
       i.on_hand_qty,
       i.reorder_point,
       i.max_stock - i.on_hand_qty                           AS suggested_order_qty,
       ROUND((i.max_stock - i.on_hand_qty) * p.unit_cost_eur, 2) AS order_value_eur
FROM inventory  i
JOIN products   p ON p.product_id   = i.product_id
JOIN suppliers  s ON s.supplier_id  = p.supplier_id
JOIN warehouses w ON w.warehouse_id = i.warehouse_id
WHERE i.on_hand_qty < i.reorder_point
ORDER BY w.warehouse_name, order_value_eur DESC;


-- Q9. How much did we spend with each supplier in 2025?
-- Skills: JOIN, SUM, COUNT(DISTINCT), WHERE on a date range
SELECT s.supplier_name,
       s.country,
       COUNT(DISTINCT po.po_id)                                  AS purchase_orders,
       ROUND(SUM(l.quantity_received * l.unit_cost_eur))         AS spend_eur
FROM purchase_orders      po
JOIN purchase_order_lines l ON l.po_id = po.po_id
JOIN suppliers            s ON s.supplier_id = po.supplier_id
WHERE po.status = 'Received'
  AND po.order_date BETWEEN '2025-01-01' AND '2025-12-31'
GROUP BY s.supplier_name, s.country
ORDER BY spend_eur DESC;


-- Q10. Which suppliers received more than 90 purchase orders?
-- Skills: GROUP BY with HAVING
SELECT s.supplier_name, COUNT(*) AS purchase_orders
FROM purchase_orders po
JOIN suppliers       s ON s.supplier_id = po.supplier_id
GROUP BY s.supplier_name
HAVING COUNT(*) > 90
ORDER BY purchase_orders DESC;


-- Q11. How does purchase spend develop month by month?
-- Skills: date functions (DATE_FORMAT), GROUP BY on an expression
SELECT DATE_FORMAT(po.order_date, '%Y-%m')               AS order_month,
       COUNT(DISTINCT po.po_id)                          AS purchase_orders,
       ROUND(SUM(l.quantity_ordered * l.unit_cost_eur))  AS ordered_value_eur
FROM purchase_orders      po
JOIN purchase_order_lines l ON l.po_id = po.po_id
WHERE po.status <> 'Cancelled'
GROUP BY order_month
ORDER BY order_month;


-- Q12. Which suppliers deliver on time, and how long do they take?
-- Skills: DATEDIFF, AVG, CASE inside an aggregate
SELECT s.supplier_name,
       COUNT(*)                                                   AS received_orders,
       ROUND(AVG(DATEDIFF(po.received_date, po.order_date)), 1)   AS avg_lead_time_days,
       ROUND(100 * AVG(CASE WHEN po.received_date <= po.expected_date THEN 1 ELSE 0 END), 1)
                                                                  AS on_time_pct,
       MAX(DATEDIFF(po.received_date, po.expected_date))          AS max_days_late
FROM purchase_orders po
JOIN suppliers       s ON s.supplier_id = po.supplier_id
WHERE po.status = 'Received'
GROUP BY s.supplier_name
ORDER BY on_time_pct;


-- Q13. Do suppliers deliver the full quantity we ordered? (fill rate)
-- Skills: SUM, ROUND, NULLIF to avoid division by zero
SELECT s.supplier_name,
       SUM(l.quantity_ordered)                                     AS units_ordered,
       SUM(l.quantity_received)                                    AS units_received,
       ROUND(100 * SUM(l.quantity_received) / NULLIF(SUM(l.quantity_ordered), 0), 1) AS fill_rate_pct
FROM purchase_orders      po
JOIN purchase_order_lines l ON l.po_id = po.po_id
JOIN suppliers            s ON s.supplier_id = po.supplier_id
WHERE po.status = 'Received'
GROUP BY s.supplier_name
ORDER BY fill_rate_pct;


-- Q14. How many purchase orders are still open per supplier? Show suppliers with none as 0.
-- Skills: LEFT JOIN (keeps every supplier), filter in the ON clause, COUNT(column) ignores NULLs
SELECT s.supplier_name,
       COUNT(po.po_id) AS open_purchase_orders
FROM suppliers s
LEFT JOIN purchase_orders po
       ON po.supplier_id = s.supplier_id
      AND po.status = 'Open'
GROUP BY s.supplier_name
ORDER BY open_purchase_orders DESC, s.supplier_name;


-- Q15. Which open purchase orders are already overdue on 31 Dec 2025?
-- Skills: joins, date comparison, DATEDIFF
SELECT po.po_id,
       s.supplier_name,
       w.warehouse_name,
       po.order_date,
       po.expected_date,
       DATEDIFF('2025-12-31', po.expected_date) AS days_overdue
FROM purchase_orders po
JOIN suppliers       s ON s.supplier_id  = po.supplier_id
JOIN warehouses      w ON w.warehouse_id = po.warehouse_id
WHERE po.status = 'Open'
  AND po.expected_date < '2025-12-31'
ORDER BY days_overdue DESC;


-- Q16. Which products cost more than the average product in their category?
-- Skills: correlated subquery
SELECT p.category, p.product_name, p.unit_cost_eur
FROM products p
WHERE p.unit_cost_eur > (SELECT AVG(p2.unit_cost_eur)
                         FROM products p2
                         WHERE p2.category = p.category)
ORDER BY p.category, p.unit_cost_eur DESC;
