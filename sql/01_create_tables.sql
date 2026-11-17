-- =============================================================================
-- 01_create_tables.sql
-- Database for the inventory and purchasing of a (fictional) office-supplies
-- distributor with three German warehouses.
-- Skills: CREATE DATABASE, CREATE TABLE, data types, PRIMARY KEY, FOREIGN KEY,
--         NOT NULL, DEFAULT, CHECK
-- Dialect: MySQL 8.0
-- =============================================================================

DROP DATABASE IF EXISTS inventory_basics;
CREATE DATABASE inventory_basics CHARACTER SET utf8mb4;
USE inventory_basics;

CREATE TABLE warehouses (
    warehouse_id    INT          PRIMARY KEY,
    warehouse_name  VARCHAR(50)  NOT NULL,
    city            VARCHAR(50)  NOT NULL
);

CREATE TABLE suppliers (
    supplier_id         INT          PRIMARY KEY,
    supplier_name       VARCHAR(100) NOT NULL,
    country             VARCHAR(50)  NOT NULL,
    city                VARCHAR(50)  NOT NULL,
    main_category       VARCHAR(50)  NOT NULL,
    payment_terms_days  INT          NOT NULL DEFAULT 30
);

CREATE TABLE products (
    product_id      INT           PRIMARY KEY,
    sku             VARCHAR(20)   NOT NULL UNIQUE,
    product_name    VARCHAR(100)  NOT NULL,
    category        VARCHAR(50)   NOT NULL,
    supplier_id     INT           NOT NULL,
    unit_cost_eur   DECIMAL(10,2) NOT NULL,
    list_price_eur  DECIMAL(10,2) NOT NULL,
    FOREIGN KEY (supplier_id) REFERENCES suppliers (supplier_id),
    CHECK (unit_cost_eur > 0 AND list_price_eur > 0)
);

-- Stock per product and warehouse on the snapshot date (31 Dec 2025)
CREATE TABLE inventory (
    warehouse_id     INT  NOT NULL,
    product_id       INT  NOT NULL,
    on_hand_qty      INT  NOT NULL,
    reorder_point    INT  NOT NULL,     -- order more when stock falls below this
    max_stock        INT  NOT NULL,     -- target stock level after a delivery
    last_count_date  DATE NOT NULL,
    PRIMARY KEY (warehouse_id, product_id),
    FOREIGN KEY (warehouse_id) REFERENCES warehouses (warehouse_id),
    FOREIGN KEY (product_id)   REFERENCES products (product_id),
    CHECK (on_hand_qty >= 0 AND reorder_point >= 0 AND max_stock >= reorder_point)
);

CREATE TABLE purchase_orders (
    po_id          INT          PRIMARY KEY,
    supplier_id    INT          NOT NULL,
    warehouse_id   INT          NOT NULL,
    order_date     DATE         NOT NULL,
    expected_date  DATE         NOT NULL,
    received_date  DATE         NULL,          -- NULL while the order is open or cancelled
    status         VARCHAR(20)  NOT NULL,
    FOREIGN KEY (supplier_id)  REFERENCES suppliers (supplier_id),
    FOREIGN KEY (warehouse_id) REFERENCES warehouses (warehouse_id),
    CHECK (status IN ('Received', 'Open', 'Cancelled'))
);

CREATE TABLE purchase_order_lines (
    po_id              INT           NOT NULL,
    line_no            INT           NOT NULL,
    product_id         INT           NOT NULL,
    quantity_ordered   INT           NOT NULL,
    quantity_received  INT           NOT NULL DEFAULT 0,
    unit_cost_eur      DECIMAL(10,2) NOT NULL,
    PRIMARY KEY (po_id, line_no),
    FOREIGN KEY (po_id)      REFERENCES purchase_orders (po_id),
    FOREIGN KEY (product_id) REFERENCES products (product_id),
    CHECK (quantity_ordered > 0 AND quantity_received >= 0)
);
