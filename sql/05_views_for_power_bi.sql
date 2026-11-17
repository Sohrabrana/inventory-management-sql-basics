-- =============================================================================
-- 05_views_for_power_bi.sql
-- Two flat views that feed a one-page Power BI report (see powerbi/).
-- Skills: CREATE VIEW, joins, CASE, calculated columns
-- =============================================================================
USE inventory_basics;

-- One row per product and warehouse, with stock value and status
CREATE OR REPLACE VIEW vw_inventory_status AS
SELECT w.warehouse_name,
       p.sku,
       p.product_name,
       p.category,
       s.supplier_name,
       i.on_hand_qty,
       i.reorder_point,
       i.max_stock,
       ROUND(i.on_hand_qty * p.unit_cost_eur, 2) AS stock_value_eur,
       CASE
           WHEN i.on_hand_qty = 0              THEN 'Out of stock'
           WHEN i.on_hand_qty < i.reorder_point THEN 'Below reorder point'
           WHEN i.on_hand_qty > i.max_stock     THEN 'Overstock'
           ELSE 'OK'
       END                                       AS stock_status,
       CASE WHEN i.on_hand_qty < i.reorder_point
            THEN i.max_stock - i.on_hand_qty ELSE 0 END AS suggested_order_qty
FROM inventory  i
JOIN products   p ON p.product_id   = i.product_id
JOIN suppliers  s ON s.supplier_id  = p.supplier_id
JOIN warehouses w ON w.warehouse_id = i.warehouse_id;

-- One row per purchase order, with lead time, delay and value
CREATE OR REPLACE VIEW vw_purchase_orders AS
SELECT po.po_id,
       s.supplier_name,
       s.country                                         AS supplier_country,
       w.warehouse_name,
       po.order_date,
       po.expected_date,
       po.received_date,
       po.status,
       DATEDIFF(po.received_date, po.order_date)         AS lead_time_days,
       CASE WHEN po.status = 'Received'
            THEN GREATEST(DATEDIFF(po.received_date, po.expected_date), 0) END AS days_late,
       CASE WHEN po.status <> 'Received' THEN NULL
            WHEN po.received_date <= po.expected_date THEN 1 ELSE 0 END        AS on_time_flag,
       SUM(l.quantity_ordered)                           AS units_ordered,
       SUM(l.quantity_received)                          AS units_received,
       ROUND(SUM(l.quantity_ordered  * l.unit_cost_eur), 2) AS ordered_value_eur,
       ROUND(SUM(l.quantity_received * l.unit_cost_eur), 2) AS received_value_eur
FROM purchase_orders      po
JOIN purchase_order_lines l ON l.po_id        = po.po_id
JOIN suppliers            s ON s.supplier_id  = po.supplier_id
JOIN warehouses           w ON w.warehouse_id = po.warehouse_id
GROUP BY po.po_id, s.supplier_name, s.country, w.warehouse_name,
         po.order_date, po.expected_date, po.received_date, po.status;
