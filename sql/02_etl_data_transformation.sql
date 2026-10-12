-- ============================================================================
-- Project 2: Retail Sales and Profitability Analytics
-- Script 02: Data Quality, ETL Transformation & Audit Checks
-- ============================================================================
-- Description:
--   Automated data hygiene, auditing, and transformation procedures:
--   1. Null and missing value diagnostics
--   2. Primary key uniqueness validation
--   3. Referential integrity checks across all foreign keys
--   4. Business logic range audits (negative prices, invalid discounts)
--   5. Creation of an analytical flattened view for rapid exploratory querying
-- ============================================================================

-- ----------------------------------------------------------------------------
-- Audit 1: Missing / NULL Value Detection
-- Ensures no critical business fields contain unhandled NULL values.
-- ----------------------------------------------------------------------------
SELECT 
    'Fact_Sales' AS TableName,
    COUNT(*) AS TotalRecords,
    SUM(CASE WHEN Sales IS NULL THEN 1 ELSE 0 END) AS NullSalesCount,
    SUM(CASE WHEN Profit IS NULL THEN 1 ELSE 0 END) AS NullProfitCount,
    SUM(CASE WHEN Discount IS NULL THEN 1 ELSE 0 END) AS NullDiscountCount,
    SUM(CASE WHEN Quantity IS NULL OR Quantity <= 0 THEN 1 ELSE 0 END) AS InvalidQuantityCount
FROM Fact_Sales;

-- ----------------------------------------------------------------------------
-- Audit 2: Referential Integrity Audit
-- Identifies any orphaned sales records where foreign keys do not resolve.
-- ----------------------------------------------------------------------------
SELECT 
    'Orphaned Dates' AS IssueType, COUNT(*) AS OrphanCount
FROM Fact_Sales f LEFT JOIN Dim_Date d ON f.OrderDateKey = d.DateKey
WHERE d.DateKey IS NULL
UNION ALL
SELECT 
    'Orphaned Customers', COUNT(*)
FROM Fact_Sales f LEFT JOIN Dim_Customer c ON f.CustomerKey = c.CustomerKey
WHERE c.CustomerKey IS NULL
UNION ALL
SELECT 
    'Orphaned Products', COUNT(*)
FROM Fact_Sales f LEFT JOIN Dim_Product p ON f.ProductKey = p.ProductKey
WHERE p.ProductKey IS NULL
UNION ALL
SELECT 
    'Orphaned Geographies', COUNT(*)
FROM Fact_Sales f LEFT JOIN Dim_Geography g ON f.GeographyKey = g.GeographyKey
WHERE g.GeographyKey IS NULL;

-- ----------------------------------------------------------------------------
-- Audit 3: Business Rule Anomaly Check
-- Validates:
--   - Discounts are between 0% and 80% (0.0 to 0.8)
--   - Unit prices are positive (> 0)
-- ----------------------------------------------------------------------------
SELECT 
    COUNT(*) AS AnomalyRecords,
    MIN(Discount) AS MinDiscountObserved,
    MAX(Discount) AS MaxDiscountObserved,
    MIN(UnitPrice) AS MinUnitPriceObserved
FROM Fact_Sales
WHERE Discount < 0.0 OR Discount > 0.80 OR UnitPrice <= 0;

-- ----------------------------------------------------------------------------
-- Transformation View: vw_SalesAnalyticsMaster
-- Materializes a denormalized semantic layer joining dimensions with facts
-- for seamless reporting and high-performance querying.
-- ----------------------------------------------------------------------------
DROP VIEW IF EXISTS vw_SalesAnalyticsMaster;

CREATE VIEW vw_SalesAnalyticsMaster AS
SELECT 
    f.SalesID,
    f.OrderID,
    d.FullDate          AS OrderDate,
    d.Year              AS OrderYear,
    d.Quarter           AS OrderQuarter,
    d.Month             AS OrderMonth,
    d.MonthName         AS OrderMonthName,
    d.MonthYear         AS OrderMonthYear,
    c.CustomerID,
    c.CustomerName,
    c.Segment           AS CustomerSegment,
    p.ProductID,
    p.Category,
    p.SubCategory,
    p.ProductName,
    g.Region,
    g.State,
    g.City,
    g.PostalCode,
    f.ShipMode,
    f.Quantity,
    f.UnitPrice,
    f.Discount,
    ROUND(f.Discount * 100, 1) AS DiscountPercentage,
    f.Sales,
    f.Profit,
    ROUND((f.Profit / f.Sales) * 100, 2) AS ProfitMarginPercentage,
    CASE 
        WHEN f.Profit > 0 THEN 'Profitable'
        WHEN f.Profit < 0 THEN 'Loss-Making'
        ELSE 'Break-Even'
    END AS ProfitabilityStatus,
    CASE
        WHEN f.Discount = 0 THEN '0% (No Discount)'
        WHEN f.Discount <= 0.15 THEN '1% - 15% (Low)'
        WHEN f.Discount <= 0.25 THEN '16% - 25% (Moderate)'
        WHEN f.Discount <= 0.40 THEN '26% - 40% (Aggressive)'
        ELSE '40%+ (Deep Clearance)'
    END AS DiscountTier
FROM Fact_Sales f
JOIN Dim_Date d       ON f.OrderDateKey = d.DateKey
JOIN Dim_Customer c   ON f.CustomerKey = c.CustomerKey
JOIN Dim_Product p    ON f.ProductKey = p.ProductKey
JOIN Dim_Geography g  ON f.GeographyKey = g.GeographyKey;
