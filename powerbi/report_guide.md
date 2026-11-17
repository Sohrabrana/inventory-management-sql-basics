# Power BI report: Inventory & Supplier Overview (one page)

A simple one-page report on the two views from [`sql/05_views_for_power_bi.sql`](../sql/05_views_for_power_bi.sql). When it is done, save it as `powerbi/inventory_overview.pbix` and add a screenshot to `powerbi/screenshots/`.

## 1. Connect
1. Install **MySQL Connector/NET** (Power BI needs it for MySQL).
2. *Get Data → MySQL database* → server `localhost`, database `inventory_basics`.
3. Load `vw_inventory_status` and `vw_purchase_orders`.

## 2. Shared warehouse filter
The two views have no common key, so add a small table that both can relate to:

```dax
Warehouses = DISTINCT ( vw_inventory_status[warehouse_name] )
```

Relate `Warehouses[warehouse_name]` one-to-many to `vw_inventory_status[warehouse_name]` and to `vw_purchase_orders[warehouse_name]`. A slicer on `Warehouses[warehouse_name]` now filters the whole page.

## 3. Measures

```dax
Stock Value =
SUM ( vw_inventory_status[stock_value_eur] )

Items to Reorder =
CALCULATE ( COUNTROWS ( vw_inventory_status ), vw_inventory_status[suggested_order_qty] > 0 )

Overstock Value =
CALCULATE ( [Stock Value], vw_inventory_status[stock_status] = "Overstock" )

Overstock % =
DIVIDE ( [Overstock Value], [Stock Value] )

Ordered Value =
CALCULATE ( SUM ( vw_purchase_orders[ordered_value_eur] ), vw_purchase_orders[status] <> "Cancelled" )

Supplier On-Time % =
AVERAGE ( vw_purchase_orders[on_time_flag] )

Avg Lead Time (days) =
AVERAGE ( vw_purchase_orders[lead_time_days] )

Fill Rate % =
DIVIDE (
    SUM ( vw_purchase_orders[units_received] ),
    CALCULATE ( SUM ( vw_purchase_orders[units_ordered] ), vw_purchase_orders[status] = "Received" )
)
```

## 4. Layout

| Area | Visual | Fields |
| --- | --- | --- |
| Top row | 5 cards | Stock Value · Items to Reorder · Overstock % · Supplier On-Time % · Avg Lead Time (days) |
| Left | Stacked bar | Y: `warehouse_name` · X: Stock Value · Legend: `stock_status` |
| Right | Table "Reorder now" | `warehouse_name`, `product_name`, `supplier_name`, `on_hand_qty`, `reorder_point`, `suggested_order_qty`; filter `suggested_order_qty` > 0 |
| Bottom left | Table "Supplier scorecard" | `supplier_name`, Ordered Value, Supplier On-Time %, Avg Lead Time (days), Fill Rate %; background colour on Supplier On-Time % |
| Bottom right | Line chart | X: `order_date` (month) · Y: Ordered Value |
| Slicer | Dropdown | `Warehouses[warehouse_name]` |

Title the page with the main finding, e.g. "19 items need reordering; furniture suppliers deliver on time less than half the time".
