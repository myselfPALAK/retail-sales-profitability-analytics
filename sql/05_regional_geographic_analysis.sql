-- ============================================================================
-- Project 2: Retail Sales and Profitability Analytics
-- Script 05: Regional & Geographic Profitability Diagnostics
-- ============================================================================
-- Description:
--   Examines geographic drivers of retail profitability:
--   - Regional performance scorecard (West, East, Central, South)
--   - State-level profitability rankings (Top profit drivers vs loss states)
--   - Central Region diagnostic: Unpacking the margin leak
--   - Category by Region cross-matrix to identify geo-product vulnerabilities
-- ============================================================================

-- ----------------------------------------------------------------------------
-- Analysis 1: Regional Performance Scorecard
-- ----------------------------------------------------------------------------
SELECT 
    g.Region,
    COUNT(DISTINCT f.OrderID)                       AS TotalOrders,
    COUNT(DISTINCT f.CustomerKey)                   AS ActiveCustomers,
    ROUND(SUM(f.Sales), 2)                          AS TotalSales,
    ROUND(SUM(f.Sales) * 100.0 / (SELECT SUM(Sales) FROM Fact_Sales), 2) AS SalesSharePct,
    ROUND(SUM(f.Profit), 2)                         AS TotalProfit,
    ROUND(SUM(f.Profit) * 100.0 / (SELECT SUM(Profit) FROM Fact_Sales), 2) AS ProfitSharePct,
    ROUND((SUM(f.Profit) / SUM(f.Sales)) * 100, 2)  AS RegionalMarginPct,
    ROUND(AVG(f.Discount) * 100, 2)                 AS AvgDiscountPct
FROM Fact_Sales f
JOIN Dim_Geography g ON f.GeographyKey = g.GeographyKey
GROUP BY g.Region
ORDER BY TotalProfit DESC;

-- ----------------------------------------------------------------------------
-- Analysis 2: State-Level Profitability League Table (Top 5 vs Bottom 5)
-- ----------------------------------------------------------------------------
WITH StateMetrics AS (
    SELECT 
        g.State,
        g.Region,
        COUNT(DISTINCT f.OrderID) AS OrderCount,
        ROUND(SUM(f.Sales), 2)    AS TotalSales,
        ROUND(SUM(f.Profit), 2)   AS TotalProfit,
        ROUND((SUM(f.Profit) / SUM(f.Sales)) * 100, 2) AS ProfitMarginPct,
        ROUND(AVG(f.Discount) * 100, 1) AS AvgDiscountPct,
        ROW_NUMBER() OVER (ORDER BY SUM(f.Profit) DESC) AS RankTopProfit,
        ROW_NUMBER() OVER (ORDER BY SUM(f.Profit) ASC)  AS RankBottomProfit
    FROM Fact_Sales f
    JOIN Dim_Geography g ON f.GeographyKey = g.GeographyKey
    GROUP BY g.State, g.Region
)
SELECT 
    'Top 5 Profitable States' AS Tier,
    State, Region, OrderCount, TotalSales, TotalProfit, ProfitMarginPct, AvgDiscountPct
FROM StateMetrics
WHERE RankTopProfit <= 5
UNION ALL
SELECT 
    'Bottom 5 Underperforming States' AS Tier,
    State, Region, OrderCount, TotalSales, TotalProfit, ProfitMarginPct, AvgDiscountPct
FROM StateMetrics
WHERE RankBottomProfit <= 5
ORDER BY TotalProfit DESC;

-- ----------------------------------------------------------------------------
-- Analysis 3: Central Region Deep Dive - Product Category Breakdown
-- Pinpoints exactly which categories drain profitability in the Central region.
-- ----------------------------------------------------------------------------
SELECT 
    p.Category,
    p.SubCategory,
    ROUND(SUM(f.Sales), 2)                          AS CentralSales,
    ROUND(SUM(f.Profit), 2)                         AS CentralProfit,
    ROUND((SUM(f.Profit) / SUM(f.Sales)) * 100, 2)  AS CentralMarginPct,
    ROUND(AVG(f.Discount) * 100, 1)                 AS CentralAvgDiscountPct,
    -- Benchmark comparison against enterprise average margin for this subcategory
    ROUND(
        (SUM(f.Profit) / SUM(f.Sales)) * 100.0 - 
        (SELECT (SUM(f2.Profit) / SUM(f2.Sales)) * 100.0 
         FROM Fact_Sales f2 
         JOIN Dim_Product p2 ON f2.ProductKey = p2.ProductKey 
         WHERE p2.SubCategory = p.SubCategory), 
        2
    ) AS MarginVarianceFromEnterpriseAvgPct
FROM Fact_Sales f
JOIN Dim_Geography g ON f.GeographyKey = g.GeographyKey
JOIN Dim_Product p   ON f.ProductKey = p.ProductKey
WHERE g.Region = 'Central'
GROUP BY p.Category, p.SubCategory
ORDER BY CentralProfit ASC;

-- ----------------------------------------------------------------------------
-- Analysis 4: Regional Category Cross-Matrix (Sales & Profit by Region x Category)
-- ----------------------------------------------------------------------------
SELECT 
    g.Region,
    ROUND(SUM(CASE WHEN p.Category = 'Furniture' THEN f.Sales ELSE 0 END), 2)       AS Furniture_Sales,
    ROUND(SUM(CASE WHEN p.Category = 'Furniture' THEN f.Profit ELSE 0 END), 2)      AS Furniture_Profit,
    ROUND(SUM(CASE WHEN p.Category = 'Office Supplies' THEN f.Sales ELSE 0 END), 2) AS Office_Sales,
    ROUND(SUM(CASE WHEN p.Category = 'Office Supplies' THEN f.Profit ELSE 0 END), 2)AS Office_Profit,
    ROUND(SUM(CASE WHEN p.Category = 'Technology' THEN f.Sales ELSE 0 END), 2)      AS Tech_Sales,
    ROUND(SUM(CASE WHEN p.Category = 'Technology' THEN f.Profit ELSE 0 END), 2)     AS Tech_Profit
FROM Fact_Sales f
JOIN Dim_Geography g ON f.GeographyKey = g.GeographyKey
JOIN Dim_Product p   ON f.ProductKey = p.ProductKey
GROUP BY g.Region
ORDER BY Tech_Profit DESC;
