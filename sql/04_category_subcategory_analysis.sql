-- ============================================================================
-- Project 2: Retail Sales and Profitability Analytics
-- Script 04: Product Category & Sub-Category Profitability Diagnostics
-- ============================================================================
-- Description:
--   Uncovers product-level performance drivers:
--   - Revenue & profit contribution by high-level Category
--   - Sub-Category performance rankings (identifying loss leaders & profit engines)
--   - Discount impact on margins within each sub-category
--   - Top 10 most profitable vs Top 10 most loss-making specific products
-- ============================================================================

-- ----------------------------------------------------------------------------
-- Analysis 1: Category-Level Performance & Portfolio Contribution
-- ----------------------------------------------------------------------------
SELECT 
    p.Category,
    COUNT(DISTINCT f.OrderID)                       AS TotalOrders,
    SUM(f.Quantity)                                 AS UnitsSold,
    ROUND(SUM(f.Sales), 2)                          AS TotalRevenue,
    ROUND(SUM(f.Sales) * 100.0 / (SELECT SUM(Sales) FROM Fact_Sales), 2) AS RevenueContributionPct,
    ROUND(SUM(f.Profit), 2)                         AS TotalProfit,
    ROUND(SUM(f.Profit) * 100.0 / (SELECT SUM(Profit) FROM Fact_Sales), 2) AS ProfitContributionPct,
    ROUND((SUM(f.Profit) / SUM(f.Sales)) * 100, 2)  AS ProfitMarginPct,
    ROUND(AVG(f.Discount) * 100, 2)                 AS AvgDiscountGivenPct
FROM Fact_Sales f
JOIN Dim_Product p ON f.ProductKey = p.ProductKey
GROUP BY p.Category
ORDER BY TotalProfit DESC;

-- ----------------------------------------------------------------------------
-- Analysis 2: Sub-Category Profitability Ranking & Loss-Maker Detection
-- Critical insight: Subcategories generating high volume but eroding margins.
-- ----------------------------------------------------------------------------
SELECT 
    p.Category,
    p.SubCategory,
    COUNT(*)                                        AS TotalTransactions,
    ROUND(SUM(f.Sales), 2)                          AS TotalRevenue,
    ROUND(SUM(f.Profit), 2)                         AS TotalProfit,
    ROUND((SUM(f.Profit) / SUM(f.Sales)) * 100, 2)  AS ProfitMarginPct,
    ROUND(AVG(f.Discount) * 100, 2)                 AS AvgDiscountPct,
    SUM(CASE WHEN f.Profit < 0 THEN 1 ELSE 0 END)   AS LossMakingTransactions,
    ROUND(
        SUM(CASE WHEN f.Profit < 0 THEN 1.0 ELSE 0.0 END) * 100.0 / COUNT(*), 
        1
    ) AS LossMakingTransactionRatePct,
    CASE 
        WHEN SUM(f.Profit) < 0 THEN 'CRITICAL: Value Destroyer'
        WHEN (SUM(f.Profit) / SUM(f.Sales)) < 0.08 THEN 'WARNING: Low Margin'
        ELSE 'HEALTHY: Profitable'
    END AS PortfolioStatus
FROM Fact_Sales f
JOIN Dim_Product p ON f.ProductKey = p.ProductKey
GROUP BY p.Category, p.SubCategory
ORDER BY TotalProfit ASC;

-- ----------------------------------------------------------------------------
-- Analysis 3: Bottom 10 Profit-Draining Products (Immediate Action Needed)
-- ----------------------------------------------------------------------------
SELECT 
    p.ProductID,
    p.ProductName,
    p.Category,
    p.SubCategory,
    COUNT(*)                                        AS OrderCount,
    SUM(f.Quantity)                                 AS TotalUnitsSold,
    ROUND(SUM(f.Sales), 2)                          AS TotalRevenueGenerated,
    ROUND(SUM(f.Profit), 2)                         AS CumulativeLossIncurred,
    ROUND((SUM(f.Profit) / SUM(f.Sales)) * 100, 2)  AS ProfitMarginPct,
    ROUND(AVG(f.Discount) * 100, 1)                 AS AvgDiscountPct
FROM Fact_Sales f
JOIN Dim_Product p ON f.ProductKey = p.ProductKey
GROUP BY p.ProductID, p.ProductName, p.Category, p.SubCategory
HAVING SUM(f.Profit) < 0
ORDER BY CumulativeLossIncurred ASC
LIMIT 10;

-- ----------------------------------------------------------------------------
-- Analysis 4: Top 10 Star Products (Value Champions)
-- ----------------------------------------------------------------------------
SELECT 
    p.ProductID,
    p.ProductName,
    p.Category,
    p.SubCategory,
    COUNT(*)                                        AS OrderCount,
    ROUND(SUM(f.Sales), 2)                          AS TotalRevenue,
    ROUND(SUM(f.Profit), 2)                         AS TotalProfit,
    ROUND((SUM(f.Profit) / SUM(f.Sales)) * 100, 2)  AS ProfitMarginPct,
    ROUND(AVG(f.Discount) * 100, 1)                 AS AvgDiscountPct
FROM Fact_Sales f
JOIN Dim_Product p ON f.ProductKey = p.ProductKey
GROUP BY p.ProductID, p.ProductName, p.Category, p.SubCategory
ORDER BY TotalProfit DESC
LIMIT 10;
