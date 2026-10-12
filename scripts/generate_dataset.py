#!/usr/bin/env python3
"""
Retail Sales & Profitability Analytics - Dataset Generator & ETL Pipeline
========================================================================
Generates a realistic, benchmark-grade retail sales dataset modeled after
the classic Global/US Superstore retail sales dataset.

Produces:
1. Raw CSV: data/raw/superstore_retail_raw.csv
2. Dimensional tables: data/processed/ (Dim_Product, Dim_Customer, Dim_Geography, Dim_Date, Fact_Sales)
3. Relational SQLite database: retail_analytics.db
4. Dashboard summary JSON: dashboard/data.json
"""

import os
import csv
import json
import random
import sqlite3
from datetime import datetime, timedelta

# Set deterministic seed for reproducibility
random.seed(42)

BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DATA_RAW_DIR = os.path.join(BASE_DIR, "data", "raw")
DATA_PROC_DIR = os.path.join(BASE_DIR, "data", "processed")
DASHBOARD_DIR = os.path.join(BASE_DIR, "dashboard")
DB_PATH = os.path.join(BASE_DIR, "retail_analytics.db")

os.makedirs(DATA_RAW_DIR, exist_ok=True)
os.makedirs(DATA_PROC_DIR, exist_ok=True)
os.makedirs(DASHBOARD_DIR, exist_ok=True)

# ---------------------------------------------------------
# Reference Metadata
# ---------------------------------------------------------

CATEGORIES = {
    "Furniture": {
        "Bookcases": [
            ("Dania Classic Library Bookcase", 350.0, 0.12),
            ("Bush Somerset Collection Bookcase", 261.96, -0.05),
            ("O'Sullivan 2-Shelf Heavy-Duty Bookcase", 119.98, -0.08),
            ("Atlantic Mobile Bookcase with Casters", 189.50, 0.04),
            ("Sauder Inglewood Collection 4-Shelf Bookcase", 299.00, -0.02)
        ],
        "Chairs": [
            ("Hon Deluxe Fabric Task Chair", 199.99, 0.18),
            ("Novimex Swivel Arm Chair", 288.75, 0.22),
            ("Global High-Back Executive Leather Chair", 429.90, 0.15),
            ("Harbour Creations Ergonomic Desk Chair", 159.20, 0.14),
            ("Office Star Executive Eco-Leather Chair", 312.40, 0.20)
        ],
        "Furnishings": [
            ("Eldon Expressions Desk Accessories", 25.40, 0.28),
            ("Howard Miller 13-Inch Wall Clock", 49.95, 0.32),
            ("Tenex Traditional Chairmats", 85.00, 0.24),
            ("Deflect-o RollaMat Clear Vinyl Mat", 62.50, 0.20),
            ("Executive High-Gloss Wastebasket", 18.25, 0.35)
        ],
        "Tables": [
            ("Chromcraft Rectangular Conference Table", 680.00, -0.15),
            ("Bevis 36 x 72 Round Training Table", 450.00, -0.20),
            ("Balt Split-Level Drafting Table", 520.00, -0.12),
            ("Hon 4060 Series Modular Workstation Table", 780.00, -0.18),
            ("Lesro Kingston Series End Table", 210.00, -0.08)
        ]
    },
    "Office Supplies": {
        "Appliances": [
            ("Hamilton Beach Toaster 4-Slice", 54.90, 0.25),
            ("Cuisinart Countertop Microwave Oven", 145.00, 0.22),
            ("Fellowes Quiet Air Purifier", 189.00, 0.28),
            ("Honeywell True HEPA Tower Air Cleaner", 169.50, 0.24),
            ("Avanti 1.7 cu. ft. Compact Refrigerator", 199.90, 0.19)
        ],
        "Art": [
            ("Newell 300 Series Colored Pencils (36-pack)", 15.60, 0.38),
            ("Prang Dustless White Chalk", 8.20, 0.42),
            ("Bostitch Heavy Duty Electric Pencil Sharpener", 34.50, 0.35),
            ("Hunt Boston School Pro Pencil Sharpener", 28.00, 0.32),
            ("Sanford Liquid Accent Highlighters (12-pack)", 12.40, 0.40)
        ],
        "Binders": [
            ("Avery Heavy-Duty View Binder, 2-Inch", 14.80, 0.30),
            ("Wilson Jones Ledger Heavy Duty Binder", 22.50, 0.25),
            ("GBC DocuBind P400 Binding Machine", 420.00, 0.35),
            ("Fellowes Binding Spines (Pack of 100)", 19.99, 0.40),
            ("Acco Pressboard Ring Binder with Tyvek Hinge", 11.20, 0.34)
        ],
        "Envelopes": [
            ("Quality Park #10 Self-Seal Security Envelopes", 18.50, 0.42),
            ("Mead Clasp Envelopes 9x12", 24.00, 0.38),
            ("Tyvek Heavy Duty Padded Envelopes", 32.50, 0.45)
        ],
        "Fasteners": [
            ("Advantus Push Pins with Clear Heads", 6.50, 0.45),
            ("Acco Banker's Clasp Clips (100-pack)", 8.90, 0.40),
            ("Staples Stainless Steel Paper Clips", 4.80, 0.48)
        ],
        "Labels": [
            ("Avery 5160 Laser Address Labels (3,000 count)", 28.50, 0.42),
            ("Dymo LabelWriter Self-Adhesive Shipping Labels", 34.00, 0.38),
            ("Avery Color-Coding Labels 3/4-inch", 9.20, 0.45)
        ],
        "Paper": [
            ("Hammermill Ultra Premium Laser Paper (500 sheets)", 14.20, 0.35),
            ("Xerox 4200 Multi-Use Copy Paper (Case)", 45.00, 0.30),
            ("Southworth 25% Cotton Resume Paper", 22.80, 0.40),
            ("Ampad Evidence Recycled Writing Pads (12-pack)", 18.90, 0.38)
        ],
        "Storage": [
            ("Fellowes Bankers Box Heavy-Duty Storage Box", 38.00, 0.28),
            ("Sterilite 3-Drawer Desktop Organizer", 24.50, 0.32),
            ("Tennsco Industrial Steel Storage Cabinet", 385.00, 0.22),
            ("Iris Plastic Stackable Craft Storage Cart", 65.00, 0.26)
        ],
        "Supplies": [
            ("Fiskars 8-Inch Commercial Scissors", 12.50, 0.25),
            ("Acme Stainless Steel Utility Shears", 16.80, 0.22),
            ("Martin Yale Heavy-Duty Guillotine Paper Trimmer", 185.00, -0.05),
            ("Stabila Heavy Duty Utility Box Cutter Blades", 9.90, 0.30)
        ]
    },
    "Technology": {
        "Accessories": [
            ("Logitech MX Master 3S Wireless Mouse", 99.99, 0.38),
            ("Anker 737 Power Bank (PowerCore 24K)", 149.99, 0.35),
            ("SanDisk Extreme Portable 1TB SSD", 129.99, 0.32),
            ("Plantronics Voyager 5200 Bluetooth Headset", 119.50, 0.30),
            ("Belkin 12-Outlet Surge Protector with USB", 39.99, 0.42)
        ],
        "Copiers": [
            ("Canon imageCLASS D1620 Multifunction Copier", 1199.00, 0.45),
            ("Hewlett-Packard LaserJet Enterprise Copier", 1799.99, 0.42),
            ("Brother Monochrome Laser Multi-Function Copier", 649.00, 0.40),
            ("Sharp AL-1530CS Digital Desktop Copier", 899.00, 0.38)
        ],
        "Machines": [
            ("Epson WorkForce Pro Color Document Scanner", 389.00, 0.18),
            ("Zebra ZP450 Thermal Label Barcode Printer", 299.00, 0.15),
            ("Konica Minolta Magicolor Laser Printer", 749.00, 0.12),
            ("Star Micronics TSP143 Thermal Receipt Printer", 229.00, 0.22)
        ],
        "Phones": [
            ("Cisco 8845 IP Business Video Desk Phone", 285.00, 0.32),
            ("Polycom SoundPoint Pro SE-225 Conference Phone", 345.00, 0.35),
            ("Grandstream GXP2170 Enterprise IP Phone", 129.00, 0.28),
            ("Yealink SIP-T54W Prime Business Phone", 189.00, 0.30),
            ("Panasonic DECT 6.0 Expandable Cordless System", 149.90, 0.26)
        ]
    }
}

GEOGRAPHY = {
    "West": [
        ("California", [("Los Angeles", "90036"), ("San Francisco", "94109"), ("San Diego", "92104"), ("San Jose", "95123"), ("Sacramento", "95823")]),
        ("Washington", [("Seattle", "98105"), ("Spokane", "99207"), ("Tacoma", "98405")]),
        ("Oregon", [("Portland", "97206"), ("Eugene", "97402"), ("Salem", "97301")]),
        ("Arizona", [("Phoenix", "85032"), ("Tucson", "85705"), ("Mesa", "85204")]),
        ("Colorado", [("Denver", "80219"), ("Colorado Springs", "80918"), ("Aurora", "80013")])
    ],
    "East": [
        ("New York", [("New York City", "10024"), ("Buffalo", "14215"), ("Rochester", "14609")]),
        ("Pennsylvania", [("Philadelphia", "19120"), ("Pittsburgh", "15213"), ("Allentown", "18102")]),
        ("Massachusetts", [("Boston", "02124"), ("Worcester", "01604"), ("Springfield", "01109")]),
        ("New Jersey", [("Newark", "07104"), ("Jersey City", "07305"), ("Paterson", "07501")]),
        ("Ohio", [("Columbus", "43229"), ("Cleveland", "44105"), ("Cincinnati", "45211")])
    ],
    "Central": [
        ("Texas", [("Houston", "77070"), ("Dallas", "75217"), ("Austin", "78745"), ("San Antonio", "78228"), ("Fort Worth", "76106")]),
        ("Illinois", [("Chicago", "60623"), ("Aurora", "60505"), ("Naperville", "60540")]),
        ("Michigan", [("Detroit", "48227"), ("Grand Rapids", "49503"), ("Warren", "48089")]),
        ("Wisconsin", [("Milwaukee", "53209"), ("Madison", "53711"), ("Green Bay", "54302")]),
        ("Indiana", [("Indianapolis", "46227"), ("Fort Wayne", "46804"), ("Evansville", "47711")])
    ],
    "South": [
        ("Florida", [("Jacksonville", "32210"), ("Miami", "33125"), ("Tampa", "33612"), ("Orlando", "32808")]),
        ("North Carolina", [("Charlotte", "28205"), ("Raleigh", "27610"), ("Greensboro", "27405")]),
        ("Georgia", [("Atlanta", "30318"), ("Augusta", "30906"), ("Savannah", "31405")]),
        ("Virginia", [("Virginia Beach", "23464"), ("Norfolk", "23503"), ("Richmond", "23223")]),
        ("Tennessee", [("Memphis", "38109"), ("Nashville", "37211"), ("Knoxville", "37918")])
    ]
}

SEGMENTS = ["Consumer", "Corporate", "Home Office"]
SEGMENT_WEIGHTS = [0.52, 0.30, 0.18]

SHIP_MODES = ["Standard Class", "Second Class", "First Class", "Same Day"]
SHIP_WEIGHTS = [0.60, 0.20, 0.15, 0.05]

FIRST_NAMES = [
    "Claire", "Brosina", "Andrew", "Harold", "Pete", "Alejandro", "Zuschuss", "Ken",
    "Sandra", "Emily", "Eric", "Tracy", "Matt", "Gene", "Linda", "David", "Karen",
    "Steven", "Maria", "Robert", "James", "Patricia", "Michael", "Barbara", "William",
    "Elizabeth", "Richard", "Susan", "Joseph", "Jessica", "Thomas", "Sarah", "Charles",
    "Christopher", "Nancy", "Daniel", "Lisa", "Matthew", "Margaret", "Anthony", "Betty",
    "Donald", "Dorothy", "Mark", "Sandra", "Paul", "Ashley", "Steven", "Kimberly"
]

LAST_NAMES = [
    "Gute", "Hoffman", "Allen", "Pawlan", "Kint", "Savely", "Donatelli", "Black",
    "Flanagan", "Phan", "Hoffmann", "Blumstein", "Connell", "Hara", "Cacioppo",
    "Smith", "Johnson", "Williams", "Brown", "Jones", "Garcia", "Miller", "Davis",
    "Rodriguez", "Martinez", "Hernandez", "Lopez", "Gonzalez", "Wilson", "Anderson",
    "Thomas", "Taylor", "Moore", "Jackson", "Martin", "Lee", "Perez", "Thompson",
    "White", "Harris", "Sanchez", "Clark", "Ramirez", "Lewis", "Robinson", "Walker"
]

def generate_customers(num_customers=793):
    customers = []
    for i in range(1, num_customers + 1):
        first = random.choice(FIRST_NAMES)
        last = random.choice(LAST_NAMES)
        cid = f"{first[:2].upper()}{last[:2].upper()}-{10000 + i}"
        name = f"{first} {last}"
        segment = random.choices(SEGMENTS, weights=SEGMENT_WEIGHTS)[0]
        customers.append({
            "CustomerKey": i,
            "CustomerID": cid,
            "CustomerName": name,
            "Segment": segment
        })
    return customers

def generate_products():
    products = []
    pid_counter = 10000
    pkey = 1
    for cat, subcats in CATEGORIES.items():
        cat_code = cat[:3].upper()
        for subcat, item_list in subcats.items():
            sub_code = subcat[:2].upper()
            for prod_name, base_price, base_margin in item_list:
                pid_counter += 1
                pid = f"{cat_code}-{sub_code}-{pid_counter}"
                products.append({
                    "ProductKey": pkey,
                    "ProductID": pid,
                    "Category": cat,
                    "SubCategory": subcat,
                    "ProductName": prod_name,
                    "BasePrice": base_price,
                    "BaseMargin": base_margin
                })
                pkey += 1
    return products

def generate_geographies():
    geographies = []
    gkey = 1
    for region, states in GEOGRAPHY.items():
        for state, cities in states:
            for city, postal in cities:
                geographies.append({
                    "GeographyKey": gkey,
                    "Country": "United States",
                    "Region": region,
                    "State": state,
                    "City": city,
                    "PostalCode": postal
                })
                gkey += 1
    return geographies

def generate_date_dimension(start_date=datetime(2021, 1, 1), end_date=datetime(2024, 12, 31)):
    dates = []
    cur = start_date
    dkey = 1
    while cur <= end_date:
        dates.append({
            "DateKey": int(cur.strftime("%Y%m%d")),
            "FullDate": cur.strftime("%Y-%m-%d"),
            "Year": cur.year,
            "Quarter": f"Q{(cur.month - 1) // 3 + 1}",
            "Month": cur.month,
            "MonthName": cur.strftime("%B"),
            "MonthYear": cur.strftime("%b %Y"),
            "DayOfMonth": cur.day,
            "DayOfWeek": cur.strftime("%A"),
            "DayOfWeekNumber": cur.isoweekday(),
            "IsWeekend": 1 if cur.isoweekday() in [6, 7] else 0
        })
        cur += timedelta(days=1)
        dkey += 1
    return dates

def generate_transactions(num_orders=9994, customers=None, products=None, geographies=None, dates=None):
    transactions = []
    raw_rows = []
    
    date_lookup = {d["FullDate"]: d["DateKey"] for d in dates}
    all_dates = [d["FullDate"] for d in dates]
    
    # Weight dates toward later years (growing business) and Q4 holiday spikes
    date_weights = []
    for d_str in all_dates:
        dt = datetime.strptime(d_str, "%Y-%m-%d")
        year_multiplier = 1.0 + (dt.year - 2021) * 0.22  # 22% annual growth
        month_multiplier = 1.6 if dt.month in [11, 12] else (1.3 if dt.month in [9, 10] else 0.9)
        date_weights.append(year_multiplier * month_multiplier)
    
    order_id_counter = 100000
    
    for i in range(1, num_orders + 1):
        order_date_str = random.choices(all_dates, weights=date_weights)[0]
        order_dt = datetime.strptime(order_date_str, "%Y-%m-%d")
        ship_days = random.choices([1, 2, 3, 4, 5, 6, 7], weights=[0.08, 0.18, 0.35, 0.22, 0.10, 0.05, 0.02])[0]
        ship_dt = order_dt + timedelta(days=ship_days)
        ship_date_str = ship_dt.strftime("%Y-%m-%d")
        ship_date_key = int(ship_dt.strftime("%Y%m%d"))
        order_date_key = date_lookup[order_date_str]
        
        customer = random.choice(customers)
        geo = random.choice(geographies)
        product = random.choice(products)
        ship_mode = random.choices(SHIP_MODES, weights=SHIP_WEIGHTS)[0]
        
        order_id_counter += 1
        order_id = f"CA-{order_dt.year}-{order_id_counter}"
        
        # Quantity between 1 and 9 (typical retail baskets)
        quantity = random.choices(range(1, 10), weights=[0.25, 0.22, 0.18, 0.12, 0.10, 0.06, 0.04, 0.02, 0.01])[0]
        
        # Realistic Discount Distribution:
        # Central region has higher aggressive discounting (mimicking real retail phenomenon in Texas/Illinois)
        if geo["Region"] == "Central" and geo["State"] in ["Texas", "Illinois"]:
            discount = random.choices([0.0, 0.1, 0.2, 0.3, 0.4, 0.6, 0.8], weights=[0.25, 0.10, 0.20, 0.15, 0.15, 0.10, 0.05])[0]
        elif product["SubCategory"] in ["Tables", "Bookcases", "Supplies"]:
            discount = random.choices([0.0, 0.1, 0.15, 0.2, 0.3, 0.4, 0.5], weights=[0.35, 0.15, 0.15, 0.15, 0.10, 0.06, 0.04])[0]
        else:
            discount = random.choices([0.0, 0.1, 0.15, 0.2, 0.3], weights=[0.55, 0.20, 0.12, 0.09, 0.04])[0]
            
        unit_price = product["BasePrice"] * random.uniform(0.95, 1.05)
        raw_sales = round(quantity * unit_price * (1.0 - discount), 2)
        if raw_sales < 1.0:
            raw_sales = 1.0
            
        # Cost of Goods Sold (COGS) based on base margin
        base_margin = product["BaseMargin"]
        unit_cost = product["BasePrice"] * (1.0 - base_margin)
        total_cost = unit_cost * quantity
        
        # Shipping overhead
        shipping_cost = round(random.uniform(3.0, 15.0) * (1.5 if ship_mode == "Same Day" else (1.2 if ship_mode == "First Class" else 1.0)), 2)
        
        # Profit = Sales - Total Cost - (fractional shipping allocated)
        # Note: When discount is >= 0.30, profit flips negative sharply
        profit = round(raw_sales - total_cost - (shipping_cost * 0.15), 2)
        
        # Ensure Central Region Tables/Supplies replicate the documented negative profit anomaly
        if geo["Region"] == "Central" and product["SubCategory"] == "Tables" and discount >= 0.20:
            profit = round(-abs(profit) * 1.25, 2)
            
        profit_margin = round((profit / raw_sales) if raw_sales > 0 else 0.0, 4)
        
        # Fact Record
        fact_record = {
            "SalesID": i,
            "OrderID": order_id,
            "OrderDateKey": order_date_key,
            "ShipDateKey": ship_date_key,
            "CustomerKey": customer["CustomerKey"],
            "ProductKey": product["ProductKey"],
            "GeographyKey": geo["GeographyKey"],
            "ShipMode": ship_mode,
            "Sales": raw_sales,
            "Quantity": quantity,
            "Discount": discount,
            "Profit": profit,
            "UnitPrice": round(unit_price, 2),
            "ShippingCost": shipping_cost,
            "ProfitMargin": profit_margin
        }
        transactions.append(fact_record)
        
        # Raw Denormalized Row (matching standard public retail dataset schemas)
        raw_row = {
            "Row ID": i,
            "Order ID": order_id,
            "Order Date": order_date_str,
            "Ship Date": ship_date_str,
            "Ship Mode": ship_mode,
            "Customer ID": customer["CustomerID"],
            "Customer Name": customer["CustomerName"],
            "Segment": customer["Segment"],
            "Country": geo["Country"],
            "City": geo["City"],
            "State": geo["State"],
            "Postal Code": geo["PostalCode"],
            "Region": geo["Region"],
            "Product ID": product["ProductID"],
            "Category": product["Category"],
            "Sub-Category": product["SubCategory"],
            "Product Name": product["ProductName"],
            "Sales": raw_sales,
            "Quantity": quantity,
            "Discount": discount,
            "Profit": profit
        }
        raw_rows.append(raw_row)
        
    return transactions, raw_rows

def save_csv(filepath, rows, fieldnames):
    with open(filepath, "w", newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(f, fieldnames=fieldnames)
        writer.writeheader()
        writer.writerows(rows)
    print(f"  [CSV] Generated {filepath} ({len(rows):,} rows)")

def build_sqlite_database(customers, products, geographies, dates, facts):
    print(f"\nBuilding SQLite Database at: {DB_PATH}")
    if os.path.exists(DB_PATH):
        os.remove(DB_PATH)
        
    conn = sqlite3.connect(DB_PATH)
    cur = conn.cursor()
    
    # Enable WAL mode & foreign keys
    cur.execute("PRAGMA journal_mode = WAL;")
    cur.execute("PRAGMA foreign_keys = ON;")
    
    # 1. Dim_Customer
    cur.execute("""
    CREATE TABLE Dim_Customer (
        CustomerKey INTEGER PRIMARY KEY,
        CustomerID TEXT NOT NULL UNIQUE,
        CustomerName TEXT NOT NULL,
        Segment TEXT NOT NULL
    );
    """)
    cur.executemany("""
    INSERT INTO Dim_Customer (CustomerKey, CustomerID, CustomerName, Segment)
    VALUES (:CustomerKey, :CustomerID, :CustomerName, :Segment);
    """, customers)
    
    # 2. Dim_Product
    cur.execute("""
    CREATE TABLE Dim_Product (
        ProductKey INTEGER PRIMARY KEY,
        ProductID TEXT NOT NULL UNIQUE,
        Category TEXT NOT NULL,
        SubCategory TEXT NOT NULL,
        ProductName TEXT NOT NULL,
        BasePrice REAL NOT NULL,
        BaseMargin REAL NOT NULL
    );
    """)
    cur.executemany("""
    INSERT INTO Dim_Product (ProductKey, ProductID, Category, SubCategory, ProductName, BasePrice, BaseMargin)
    VALUES (:ProductKey, :ProductID, :Category, :SubCategory, :ProductName, :BasePrice, :BaseMargin);
    """, products)
    
    # 3. Dim_Geography
    cur.execute("""
    CREATE TABLE Dim_Geography (
        GeographyKey INTEGER PRIMARY KEY,
        Country TEXT NOT NULL,
        Region TEXT NOT NULL,
        State TEXT NOT NULL,
        City TEXT NOT NULL,
        PostalCode TEXT NOT NULL
    );
    """)
    cur.executemany("""
    INSERT INTO Dim_Geography (GeographyKey, Country, Region, State, City, PostalCode)
    VALUES (:GeographyKey, :Country, :Region, :State, :City, :PostalCode);
    """, geographies)
    
    # 4. Dim_Date
    cur.execute("""
    CREATE TABLE Dim_Date (
        DateKey INTEGER PRIMARY KEY,
        FullDate TEXT NOT NULL,
        Year INTEGER NOT NULL,
        Quarter TEXT NOT NULL,
        Month INTEGER NOT NULL,
        MonthName TEXT NOT NULL,
        MonthYear TEXT NOT NULL,
        DayOfMonth INTEGER NOT NULL,
        DayOfWeek TEXT NOT NULL,
        DayOfWeekNumber INTEGER NOT NULL,
        IsWeekend INTEGER NOT NULL
    );
    """)
    cur.executemany("""
    INSERT INTO Dim_Date (DateKey, FullDate, Year, Quarter, Month, MonthName, MonthYear, DayOfMonth, DayOfWeek, DayOfWeekNumber, IsWeekend)
    VALUES (:DateKey, :FullDate, :Year, :Quarter, :Month, :MonthName, :MonthYear, :DayOfMonth, :DayOfWeek, :DayOfWeekNumber, :IsWeekend);
    """, dates)
    
    # 5. Fact_Sales
    cur.execute("""
    CREATE TABLE Fact_Sales (
        SalesID INTEGER PRIMARY KEY,
        OrderID TEXT NOT NULL,
        OrderDateKey INTEGER NOT NULL,
        ShipDateKey INTEGER NOT NULL,
        CustomerKey INTEGER NOT NULL,
        ProductKey INTEGER NOT NULL,
        GeographyKey INTEGER NOT NULL,
        ShipMode TEXT NOT NULL,
        Sales REAL NOT NULL,
        Quantity INTEGER NOT NULL,
        Discount REAL NOT NULL,
        Profit REAL NOT NULL,
        UnitPrice REAL NOT NULL,
        ShippingCost REAL NOT NULL,
        ProfitMargin REAL NOT NULL,
        FOREIGN KEY (OrderDateKey) REFERENCES Dim_Date(DateKey),
        FOREIGN KEY (CustomerKey) REFERENCES Dim_Customer(CustomerKey),
        FOREIGN KEY (ProductKey) REFERENCES Dim_Product(ProductKey),
        FOREIGN KEY (GeographyKey) REFERENCES Dim_Geography(GeographyKey)
    );
    """)
    cur.executemany("""
    INSERT INTO Fact_Sales (
        SalesID, OrderID, OrderDateKey, ShipDateKey, CustomerKey, ProductKey,
        GeographyKey, ShipMode, Sales, Quantity, Discount, Profit, UnitPrice,
        ShippingCost, ProfitMargin
    ) VALUES (
        :SalesID, :OrderID, :OrderDateKey, :ShipDateKey, :CustomerKey, :ProductKey,
        :GeographyKey, :ShipMode, :Sales, :Quantity, :Discount, :Profit, :UnitPrice,
        :ShippingCost, :ProfitMargin
    );
    """, facts)
    
    # Indexes for analytics performance
    cur.execute("CREATE INDEX idx_fact_orderdate ON Fact_Sales(OrderDateKey);")
    cur.execute("CREATE INDEX idx_fact_customer ON Fact_Sales(CustomerKey);")
    cur.execute("CREATE INDEX idx_fact_product ON Fact_Sales(ProductKey);")
    cur.execute("CREATE INDEX idx_fact_geography ON Fact_Sales(GeographyKey);")
    
    conn.commit()
    conn.close()
    print("  [DB] SQLite Database loaded and indexed successfully.")

def export_dashboard_json(facts, products, geographies, dates):
    """Generates precomputed summary metrics for the interactive browser dashboard."""
    print(f"\nGenerating Dashboard summary data at: {os.path.join(DASHBOARD_DIR, 'data.json')}")
    
    # Lookups
    prod_map = {p["ProductKey"]: p for p in products}
    geo_map = {g["GeographyKey"]: g for g in geographies}
    date_map = {d["DateKey"]: d for d in dates}
    
    total_sales = sum(f["Sales"] for f in facts)
    total_profit = sum(f["Profit"] for f in facts)
    total_orders = len(set(f["OrderID"] for f in facts))
    total_quantity = sum(f["Quantity"] for f in facts)
    avg_discount = sum(f["Discount"] for f in facts) / len(facts)
    overall_margin = (total_profit / total_sales) * 100 if total_sales else 0
    
    # By Year
    by_year = {}
    for f in facts:
        d = date_map.get(f["OrderDateKey"])
        if not d: continue
        yr = str(d["Year"])
        if yr not in by_year:
            by_year[yr] = {"sales": 0, "profit": 0, "orders": set(), "quantity": 0}
        by_year[yr]["sales"] += f["Sales"]
        by_year[yr]["profit"] += f["Profit"]
        by_year[yr]["orders"].add(f["OrderID"])
        by_year[yr]["quantity"] += f["Quantity"]
        
    year_summary = []
    for yr in sorted(by_year.keys()):
        s = by_year[yr]["sales"]
        p = by_year[yr]["profit"]
        year_summary.append({
            "year": yr,
            "sales": round(s, 2),
            "profit": round(p, 2),
            "orders": len(by_year[yr]["orders"]),
            "margin_pct": round((p / s) * 100, 2)
        })
        
    # By Category & SubCategory
    by_category = {}
    by_subcategory = {}
    for f in facts:
        p = prod_map[f["ProductKey"]]
        cat = p["Category"]
        sub = p["SubCategory"]
        
        if cat not in by_category:
            by_category[cat] = {"sales": 0, "profit": 0, "quantity": 0}
        by_category[cat]["sales"] += f["Sales"]
        by_category[cat]["profit"] += f["Profit"]
        by_category[cat]["quantity"] += f["Quantity"]
        
        if sub not in by_subcategory:
            by_subcategory[sub] = {"category": cat, "sales": 0, "profit": 0, "discounts": []}
        by_subcategory[sub]["sales"] += f["Sales"]
        by_subcategory[sub]["profit"] += f["Profit"]
        by_subcategory[sub]["discounts"].append(f["Discount"])
        
    category_summary = [
        {
            "category": k,
            "sales": round(v["sales"], 2),
            "profit": round(v["profit"], 2),
            "margin_pct": round((v["profit"] / v["sales"]) * 100, 2)
        }
        for k, v in by_category.items()
    ]
    
    subcategory_summary = [
        {
            "subcategory": k,
            "category": v["category"],
            "sales": round(v["sales"], 2),
            "profit": round(v["profit"], 2),
            "margin_pct": round((v["profit"] / v["sales"]) * 100, 2),
            "avg_discount_pct": round((sum(v["discounts"]) / len(v["discounts"])) * 100, 1)
        }
        for k, v in sorted(by_subcategory.items(), key=lambda x: x[1]["sales"], reverse=True)
    ]
    
    # By Region
    by_region = {}
    for f in facts:
        g = geo_map[f["GeographyKey"]]
        reg = g["Region"]
        if reg not in by_region:
            by_region[reg] = {"sales": 0, "profit": 0, "discounts": [], "orders": set()}
        by_region[reg]["sales"] += f["Sales"]
        by_region[reg]["profit"] += f["Profit"]
        by_region[reg]["discounts"].append(f["Discount"])
        by_region[reg]["orders"].add(f["OrderID"])
        
    region_summary = [
        {
            "region": k,
            "sales": round(v["sales"], 2),
            "profit": round(v["profit"], 2),
            "orders": len(v["orders"]),
            "margin_pct": round((v["profit"] / v["sales"]) * 100, 2),
            "avg_discount_pct": round((sum(v["discounts"]) / len(v["discounts"])) * 100, 1)
        }
        for k, v in sorted(by_region.items(), key=lambda x: x[1]["sales"], reverse=True)
    ]
    
    # By State
    by_state = {}
    for f in facts:
        g = geo_map[f["GeographyKey"]]
        st = g["State"]
        if st not in by_state:
            by_state[st] = {"region": g["Region"], "sales": 0, "profit": 0}
        by_state[st]["sales"] += f["Sales"]
        by_state[st]["profit"] += f["Profit"]
        
    state_summary = [
        {
            "state": k,
            "region": v["region"],
            "sales": round(v["sales"], 2),
            "profit": round(v["profit"], 2),
            "margin_pct": round((v["profit"] / v["sales"]) * 100, 2)
        }
        for k, v in sorted(by_state.items(), key=lambda x: x[1]["sales"], reverse=True)
    ]
    
    # Monthly Trends (aggregated by MonthYear chronological)
    by_month = {}
    for f in facts:
        d = date_map.get(f["OrderDateKey"])
        if not d: continue
        my_key = f"{d['Year']}-{str(d['Month']).zfill(2)}"
        my_label = d["MonthYear"]
        if my_key not in by_month:
            by_month[my_key] = {"label": my_label, "sales": 0, "profit": 0}
        by_month[my_key]["sales"] += f["Sales"]
        by_month[my_key]["profit"] += f["Profit"]
        
    monthly_trend = [
        {
            "key": k,
            "month": v["label"],
            "sales": round(v["sales"], 2),
            "profit": round(v["profit"], 2),
            "margin_pct": round((v["profit"] / v["sales"]) * 100, 2)
        }
        for k, v in sorted(by_month.items())
    ]
    
    # Discount sensitivity analysis brackets
    brackets = {
        "0% (No Discount)": {"sales": 0, "profit": 0, "count": 0},
        "1% - 15%": {"sales": 0, "profit": 0, "count": 0},
        "16% - 25%": {"sales": 0, "profit": 0, "count": 0},
        "26% - 40%": {"sales": 0, "profit": 0, "count": 0},
        "40%+ (Deep Discount)": {"sales": 0, "profit": 0, "count": 0}
    }
    
    for f in facts:
        d = f["Discount"]
        if d == 0:
            b = "0% (No Discount)"
        elif d <= 0.15:
            b = "1% - 15%"
        elif d <= 0.25:
            b = "16% - 25%"
        elif d <= 0.40:
            b = "26% - 40%"
        else:
            b = "40%+ (Deep Discount)"
            
        brackets[b]["sales"] += f["Sales"]
        brackets[b]["profit"] += f["Profit"]
        brackets[b]["count"] += 1
        
    discount_sensitivity = [
        {
            "tier": k,
            "sales": round(v["sales"], 2),
            "profit": round(v["profit"], 2),
            "orders_count": v["count"],
            "margin_pct": round((v["profit"] / v["sales"]) * 100, 2) if v["sales"] else 0
        }
        for k, v in brackets.items()
    ]
    
    dashboard_payload = {
        "metadata": {
            "title": "Retail Sales and Profitability Executive Dashboard",
            "last_updated": datetime.now().strftime("%Y-%m-%d %H:%M:%S"),
            "dataset_rows": len(facts)
        },
        "kpis": {
            "total_sales": round(total_sales, 2),
            "total_profit": round(total_profit, 2),
            "overall_margin_pct": round(overall_margin, 2),
            "total_orders": total_orders,
            "total_quantity": total_quantity,
            "avg_order_value": round(total_sales / total_orders, 2) if total_orders else 0,
            "avg_discount_pct": round(avg_discount * 100, 2)
        },
        "yearly_performance": year_summary,
        "category_performance": category_summary,
        "subcategory_performance": subcategory_summary,
        "regional_performance": region_summary,
        "state_performance": state_summary,
        "monthly_trend": monthly_trend,
        "discount_sensitivity": discount_sensitivity
    }
    
    with open(os.path.join(DASHBOARD_DIR, "data.json"), "w", encoding="utf-8") as f:
        json.dump(dashboard_payload, f, indent=2)
    print("  [JSON] Dashboard JSON exported successfully.")

def main():
    print("=" * 70)
    print("Retail Sales & Profitability Analytics - ETL Generator")
    print("=" * 70)
    
    print("\n1. Generating Dimension Entities...")
    customers = generate_customers(num_customers=793)
    products = generate_products()
    geographies = generate_geographies()
    dates = generate_date_dimension()
    print(f"  Customers: {len(customers):,} | Products: {len(products):,} | Geographies: {len(geographies):,} | Dates: {len(dates):,}")
    
    print("\n2. Generating 9,994 Retail Transactions...")
    facts, raw_rows = generate_transactions(
        num_orders=9994,
        customers=customers,
        products=products,
        geographies=geographies,
        dates=dates
    )
    print(f"  Generated {len(facts):,} fact records.")
    
    print("\n3. Exporting CSV Datasets...")
    # Raw dataset
    raw_path = os.path.join(DATA_RAW_DIR, "superstore_retail_raw.csv")
    raw_headers = list(raw_rows[0].keys())
    save_csv(raw_path, raw_rows, raw_headers)
    
    # Processed Dimensions
    save_csv(os.path.join(DATA_PROC_DIR, "dim_customers.csv"), customers, list(customers[0].keys()))
    
    # Clean Product without base metadata for consumer model
    prod_fields = ["ProductKey", "ProductID", "Category", "SubCategory", "ProductName"]
    prod_clean = [{k: p[k] for k in prod_fields} for p in products]
    save_csv(os.path.join(DATA_PROC_DIR, "dim_products.csv"), prod_clean, prod_fields)
    
    save_csv(os.path.join(DATA_PROC_DIR, "dim_geography.csv"), geographies, list(geographies[0].keys()))
    save_csv(os.path.join(DATA_PROC_DIR, "dim_date.csv"), dates, list(dates[0].keys()))
    
    # Processed Fact
    fact_fields = [
        "SalesID", "OrderID", "OrderDateKey", "ShipDateKey", "CustomerKey",
        "ProductKey", "GeographyKey", "ShipMode", "Sales", "Quantity",
        "Discount", "Profit", "UnitPrice", "ShippingCost", "ProfitMargin"
    ]
    save_csv(os.path.join(DATA_PROC_DIR, "fact_sales.csv"), facts, fact_fields)
    
    print("\n4. Building SQLite Database...")
    build_sqlite_database(customers, products, geographies, dates, facts)
    
    print("\n5. Exporting Browser Dashboard Payload...")
    export_dashboard_json(facts, products, geographies, dates)
    
    print("\n" + "=" * 70)
    print("ETL Data Generation Complete!")
    print("=" * 70)

if __name__ == "__main__":
    main()
