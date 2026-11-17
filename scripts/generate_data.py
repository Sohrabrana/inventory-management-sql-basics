#!/usr/bin/env python3
"""
Generate the synthetic dataset for the Inventory & Purchasing SQL basics project.

Everything here is fictional: the company, suppliers, products and prices.
The fixed random seed makes the data fully reproducible.

Usage:  python3 scripts/generate_data.py
Output: CSV files in ./data
"""
import csv
import random
from datetime import date, timedelta
from pathlib import Path

SEED = 7
START, END = date(2025, 1, 1), date(2025, 12, 31)
SNAPSHOT = date(2025, 12, 31)          # inventory snapshot / "today" for open orders
OUT = Path(__file__).resolve().parent.parent / "data"
rng = random.Random(SEED)

WAREHOUSES = [(1, "WH Duisburg", "Duisburg"), (2, "WH Hamburg", "Hamburg"), (3, "WH Nuremberg", "Nuremberg")]

# supplier_id, name, country, city, category, standard lead time (days), avg days late, fill rate, payment terms
SUPPLIERS = [
    (1, "Alpha Paper Supply", "Germany", "Düren", "Paper & Printing", 5, 0.5, 0.99, 30),
    (2, "Eta Paper Mills", "Poland", "Poznań", "Paper & Printing", 9, 3.0, 0.94, 60),
    (3, "Beta Packaging", "Germany", "Bielefeld", "Packaging", 4, 0.4, 0.99, 30),
    (4, "Theta Packaging", "Netherlands", "Venlo", "Packaging", 6, 1.5, 0.97, 45),
    (5, "Gamma Office Furniture", "Germany", "Stuttgart", "Office Furniture", 14, 2.0, 0.98, 30),
    (6, "Iota Office Furniture", "Czechia", "Brno", "Office Furniture", 21, 4.0, 0.95, 60),
    (7, "Delta IT Accessories", "Germany", "Frankfurt am Main", "IT Accessories", 3, 0.3, 0.99, 14),
    (8, "Epsilon Hygiene", "Germany", "Hannover", "Cleaning & Hygiene", 5, 0.8, 0.98, 30),
    (9, "Kappa Cleaning", "Austria", "Linz", "Cleaning & Hygiene", 7, 2.5, 0.96, 45),
    (10, "Zeta Breakroom Supplies", "Germany", "Bremen", "Breakroom", 4, 0.6, 0.99, 30),
]

CATALOG = {
    "Paper & Printing": (0.72, 3.0, [
        ("Copy Paper A4 80g (500 sheets)", 4.90), ("Copy Paper A4 Box (5 x 500)", 23.50),
        ("Recycled Paper A4 (500 sheets)", 5.40), ("Toner Cartridge Black", 69.00),
        ("Toner Cartridge Colour Set", 189.00), ("Inkjet Cartridge Black", 24.90),
        ("Label Sheets A4 (100)", 18.90), ("Envelopes C4 (250)", 21.50),
        ("Envelopes DL (500)", 14.90), ("Notebooks A5 (10-pack)", 19.90)]),
    "Packaging": (0.62, 2.6, [
        ("Shipping Box S (25-pack)", 17.50), ("Shipping Box M (25-pack)", 24.90),
        ("Shipping Box L (20-pack)", 29.90), ("Packing Tape (6 rolls)", 11.90),
        ("Bubble Wrap Roll 50 m", 22.90), ("Stretch Film (6 rolls)", 39.90),
        ("Pallet Labels (500)", 16.50), ("Void Fill Paper Roll", 27.50),
        ("Mailer Bags (100)", 14.90), ("Tape Dispenser Pro", 19.90)]),
    "Breakroom": (0.70, 1.8, [
        ("Coffee Beans 1 kg", 17.90), ("Coffee Capsules (100)", 34.90),
        ("Tea Assortment (6 x 25)", 12.90), ("Paper Cups (1000)", 39.90),
        ("Milk Portions (240)", 24.90), ("Sugar Sticks (1000)", 16.90),
        ("Still Water 12 x 1.5 L", 7.90), ("Cookie Assortment", 9.90),
        ("Dish Soap 5 L", 11.90), ("Kitchen Towels (8 rolls)", 8.90)]),
    "Cleaning & Hygiene": (0.64, 1.6, [
        ("Hand Soap 5 L", 14.90), ("Disinfectant Spray (12)", 49.90),
        ("Toilet Paper (64 rolls)", 34.90), ("Paper Towels Z-fold (3000)", 29.90),
        ("Bin Bags 120 L (250)", 32.90), ("Microfibre Cloths (50)", 24.90),
        ("Floor Cleaner 10 L", 27.90), ("Nitrile Gloves (1000)", 59.90),
        ("Hand Sanitiser 1 L (6)", 39.90), ("Cleaning Trolley", 189.00)]),
    "IT Accessories": (0.66, 1.0, [
        ("Wireless Mouse", 19.90), ("Keyboard USB", 34.90),
        ("USB-C Hub 7-in-1", 39.90), ("Headset USB", 59.90),
        ("Webcam Full HD", 69.90), ("HDMI Cable 2 m", 9.90),
        ("Laptop Stand", 34.90), ("Power Strip 6-way", 17.90),
        ("Monitor 24 inch", 169.00), ("Docking Station USB-C", 149.00)]),
    "Office Furniture": (0.58, 0.45, [
        ("Office Chair Basic", 149.00), ("Office Chair Ergonomic", 329.00),
        ("Desk 160 x 80", 279.00), ("Height-Adjustable Desk", 549.00),
        ("Filing Cabinet", 189.00), ("Monitor Arm", 89.00),
        ("Footrest", 39.00), ("Desk Lamp LED", 49.00),
        ("Whiteboard 120 x 90", 99.00), ("Shelf Unit", 129.00)]),
}


def write(name, rows, fields):
    OUT.mkdir(parents=True, exist_ok=True)
    with open(OUT / f"{name}.csv", "w", newline="", encoding="utf-8") as f:
        w = csv.DictWriter(f, fieldnames=fields, extrasaction="ignore", lineterminator="\n")
        w.writeheader()
        for r in rows:
            w.writerow({k: ("" if r[k] is None else r[k]) for k in fields})
    print(f"{name:22s} {len(rows):>5,d} rows")


# ---------------------------------------------------------------- products
products, pid = [], 0
for category, (cost_ratio, cat_weight, items) in CATALOG.items():
    cat_suppliers = [s for s in SUPPLIERS if s[4] == category]
    for rank, (name, price) in enumerate(items, start=1):
        pid += 1
        supplier = cat_suppliers[(rank - 1) % len(cat_suppliers)]
        demand = cat_weight / rank ** 1.1                        # relative weekly demand
        weekly_units = max(1, round(demand * (40 if price < 30 else 12 if price < 100 else 3)))
        products.append({
            "product_id": pid, "sku": f"SKU-{pid:04d}", "product_name": name, "category": category,
            "supplier_id": supplier[0], "unit_cost_eur": round(price * cost_ratio, 2),
            "list_price_eur": price, "_weekly": weekly_units,
        })

# ---------------------------------------------------------------- purchase orders
pos, lines, po_id = [], [], 1000
for wh_id, _, _ in WAREHOUSES:
    for sup in SUPPLIERS:
        sid, _, _, _, _, lead, late_avg, fill, _ = sup
        sup_products = [p for p in products if p["supplier_id"] == sid]
        d = START + timedelta(days=rng.randint(0, 10))
        interval = 14 if lead >= 14 else 10
        while d <= END:
            po_id += 1
            expected = d + timedelta(days=lead)
            late = max(0, round(rng.expovariate(1 / late_avg))) if rng.random() < 0.55 else 0
            received = expected + timedelta(days=late) - timedelta(days=1 if rng.random() < 0.1 else 0)
            if rng.random() < 0.02:
                status, received = "Cancelled", None
            elif received > SNAPSHOT:
                status, received = "Open", None
            else:
                status = "Received"
            pos.append({"po_id": po_id, "supplier_id": sid, "warehouse_id": wh_id, "order_date": d,
                        "expected_date": expected, "received_date": received, "status": status})
            chosen = rng.sample(sup_products, k=min(len(sup_products), rng.randint(2, 5)))
            for line_no, p in enumerate(chosen, start=1):
                qty = max(1, round(p["_weekly"] * interval / 7 * rng.uniform(0.7, 1.4)))
                if status == "Received":
                    q_rec = qty if rng.random() < fill else max(0, round(qty * rng.uniform(0.5, 0.9)))
                else:
                    q_rec = 0
                cost = round(p["unit_cost_eur"] * (1.03 if d.month >= 7 else 1.0), 2)
                lines.append({"po_id": po_id, "line_no": line_no, "product_id": p["product_id"],
                              "quantity_ordered": qty, "quantity_received": q_rec, "unit_cost_eur": cost})
            d += timedelta(days=interval + rng.randint(-2, 3))

# ---------------------------------------------------------------- inventory snapshot
inventory = []
for wh_id, _, _ in WAREHOUSES:
    for p in products:
        sup_lead = next(s[5] for s in SUPPLIERS if s[0] == p["supplier_id"])
        daily = p["_weekly"] / 7
        reorder_point = max(2, round(daily * (sup_lead + 5)))     # cover lead time + 5 days safety
        max_stock = reorder_point + max(5, round(p["_weekly"] * 3))
        r = rng.random()
        if r < 0.15:
            on_hand = rng.randint(0, reorder_point - 1)            # below reorder point
        elif r < 0.27:
            on_hand = rng.randint(max_stock + 1, round(max_stock * 1.6) + 1)  # overstock
        else:
            on_hand = rng.randint(reorder_point, max_stock)
        inventory.append({"warehouse_id": wh_id, "product_id": p["product_id"], "on_hand_qty": on_hand,
                          "reorder_point": reorder_point, "max_stock": max_stock,
                          "last_count_date": SNAPSHOT - timedelta(days=rng.randint(0, 60))})

write("warehouses", [dict(zip(["warehouse_id", "warehouse_name", "city"], w)) for w in WAREHOUSES],
      ["warehouse_id", "warehouse_name", "city"])
write("suppliers", [dict(zip(["supplier_id", "supplier_name", "country", "city", "main_category",
                              "_lead", "_late", "_fill", "payment_terms_days"], s)) for s in SUPPLIERS],
      ["supplier_id", "supplier_name", "country", "city", "main_category", "payment_terms_days"])
write("products", products, ["product_id", "sku", "product_name", "category", "supplier_id",
                             "unit_cost_eur", "list_price_eur"])
write("inventory", inventory, ["warehouse_id", "product_id", "on_hand_qty", "reorder_point",
                               "max_stock", "last_count_date"])
write("purchase_orders", pos, ["po_id", "supplier_id", "warehouse_id", "order_date",
                               "expected_date", "received_date", "status"])
write("purchase_order_lines", lines, ["po_id", "line_no", "product_id", "quantity_ordered",
                                      "quantity_received", "unit_cost_eur"])
