-- ============================================================================
-- Project 2: Retail Sales and Profitability Analytics
-- Script 01: Star Schema Database Schema Definition (DDL)
-- ============================================================================
-- Description:
--   Defines the Kimball-style dimensional model (Star Schema) consisting of:
--   - 4 Dimension Tables: Dim_Customer, Dim_Product, Dim_Geography, Dim_Date
--   - 1 Fact Table: Fact_Sales (containing granular transactional metrics)
--   - Optimized B-Tree indexes for analytical query acceleration.
--
-- Supported Dialects: SQLite, PostgreSQL, MySQL, Snowflake, SQL Server
-- ============================================================================

-- Drop existing tables if re-running
DROP TABLE IF EXISTS Fact_Sales;
DROP TABLE IF EXISTS Dim_Date;
DROP TABLE IF EXISTS Dim_Geography;
DROP TABLE IF EXISTS Dim_Product;
DROP TABLE IF EXISTS Dim_Customer;

-- ----------------------------------------------------------------------------
-- 1. Dim_Customer
-- Description: Customer profile and market segment classifications
-- ----------------------------------------------------------------------------
CREATE TABLE Dim_Customer (
    CustomerKey     INTEGER PRIMARY KEY,
    CustomerID      VARCHAR(20) NOT NULL UNIQUE,
    CustomerName    VARCHAR(100) NOT NULL,
    Segment         VARCHAR(50) NOT NULL   -- 'Consumer', 'Corporate', 'Home Office'
);

-- ----------------------------------------------------------------------------
-- 2. Dim_Product
-- Description: Product hierarchy spanning Category and Sub-Category
-- ----------------------------------------------------------------------------
CREATE TABLE Dim_Product (
    ProductKey      INTEGER PRIMARY KEY,
    ProductID       VARCHAR(30) NOT NULL UNIQUE,
    Category        VARCHAR(50) NOT NULL,  -- 'Technology', 'Furniture', 'Office Supplies'
    SubCategory     VARCHAR(50) NOT NULL,  -- 'Chairs', 'Tables', 'Phones', 'Binders', etc.
    ProductName     VARCHAR(255) NOT NULL,
    BasePrice       NUMERIC(10, 2) NOT NULL,
    BaseMargin      NUMERIC(5, 4) NOT NULL
);

-- ----------------------------------------------------------------------------
-- 3. Dim_Geography
-- Description: Hierarchical geographic breakdown (Country -> Region -> State -> City -> PostalCode)
-- ----------------------------------------------------------------------------
CREATE TABLE Dim_Geography (
    GeographyKey    INTEGER PRIMARY KEY,
    Country         VARCHAR(50) NOT NULL DEFAULT 'United States',
    Region          VARCHAR(50) NOT NULL,  -- 'West', 'East', 'Central', 'South'
    State           VARCHAR(50) NOT NULL,
    City            VARCHAR(100) NOT NULL,
    PostalCode      VARCHAR(20) NOT NULL
);

-- ----------------------------------------------------------------------------
-- 4. Dim_Date
-- Description: Pre-computed date dimension enabling rich time-intelligence analytics
-- ----------------------------------------------------------------------------
CREATE TABLE Dim_Date (
    DateKey             INTEGER PRIMARY KEY,  -- Formatted as YYYYMMDD (e.g., 20230514)
    FullDate            DATE NOT NULL,
    Year                INTEGER NOT NULL,
    Quarter             VARCHAR(5) NOT NULL,  -- 'Q1', 'Q2', 'Q3', 'Q4'
    Month               INTEGER NOT NULL,     -- 1 through 12
    MonthName           VARCHAR(20) NOT NULL, -- 'January' ... 'December'
    MonthYear           VARCHAR(20) NOT NULL, -- 'Jan 2023'
    DayOfMonth          INTEGER NOT NULL,     -- 1 through 31
    DayOfWeek           VARCHAR(20) NOT NULL, -- 'Monday' ... 'Sunday'
    DayOfWeekNumber     INTEGER NOT NULL,     -- 1 (Monday) to 7 (Sunday)
    IsWeekend           INTEGER NOT NULL      -- 1 = Weekend, 0 = Weekday
);

-- ----------------------------------------------------------------------------
-- 5. Fact_Sales
-- Description: Central fact table storing line-item sales transactions, costs, and profits
-- ----------------------------------------------------------------------------
CREATE TABLE Fact_Sales (
    SalesID         INTEGER PRIMARY KEY,
    OrderID         VARCHAR(30) NOT NULL,
    OrderDateKey    INTEGER NOT NULL,
    ShipDateKey     INTEGER NOT NULL,
    CustomerKey     INTEGER NOT NULL,
    ProductKey      INTEGER NOT NULL,
    GeographyKey    INTEGER NOT NULL,
    ShipMode        VARCHAR(50) NOT NULL,     -- 'Standard Class', 'Second Class', 'First Class', 'Same Day'
    Sales           NUMERIC(12, 2) NOT NULL,  -- Net realized sales revenue
    Quantity        INTEGER NOT NULL,         -- Quantity of units purchased
    Discount        NUMERIC(5, 4) NOT NULL,   -- Discount percentage (0.00 to 0.80)
    Profit          NUMERIC(12, 2) NOT NULL,  -- Net profit (positive or negative)
    UnitPrice       NUMERIC(10, 2) NOT NULL,  -- Pre-discount unit list price
    ShippingCost    NUMERIC(10, 2) NOT NULL,  -- Shipping fulfillment cost
    ProfitMargin    NUMERIC(7, 4) NOT NULL,   -- Profit / Sales ratio
    
    -- Foreign Key Constraints ensuring referential integrity
    CONSTRAINT fk_sales_orderdate   FOREIGN KEY (OrderDateKey)  REFERENCES Dim_Date(DateKey),
    CONSTRAINT fk_sales_customer    FOREIGN KEY (CustomerKey)   REFERENCES Dim_Customer(CustomerKey),
    CONSTRAINT fk_sales_product     FOREIGN KEY (ProductKey)    REFERENCES Dim_Product(ProductKey),
    CONSTRAINT fk_sales_geography   FOREIGN KEY (GeographyKey)  REFERENCES Dim_Geography(GeographyKey)
);

-- ----------------------------------------------------------------------------
-- Analytical Performance Indexes
-- ----------------------------------------------------------------------------
CREATE INDEX idx_fact_sales_orderdate   ON Fact_Sales(OrderDateKey);
CREATE INDEX idx_fact_sales_customer    ON Fact_Sales(CustomerKey);
CREATE INDEX idx_fact_sales_product     ON Fact_Sales(ProductKey);
CREATE INDEX idx_fact_sales_geography   ON Fact_Sales(GeographyKey);
CREATE INDEX idx_fact_sales_orderid     ON Fact_Sales(OrderID);
CREATE INDEX idx_dim_product_category   ON Dim_Product(Category, SubCategory);
CREATE INDEX idx_dim_geo_region_state   ON Dim_Geography(Region, State);
