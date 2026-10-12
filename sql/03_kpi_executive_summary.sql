-- ============================================================================
-- Project 2: Retail Sales and Profitability Analytics
-- Script 03: Executive Summary & Core Financial KPIs
-- ============================================================================
-- Description:
--   High-level executive dashboard metrics:
--   - Gross Revenue, Total Profit, Profit Margin %
--   - Order Volume, Unique Customers, Average Order Value (AOV)
--   - Loss-making Order count and value impact
--   - Year-over-Year (YoY) revenue & profit expansion
-- ============================================================================

-- ----------------------------------------------------------------------------
-- KPI 1: Enterprise Overall Financial Summary
-- ----------------------------------------------------------------------------
SELECT 
    COUNT(DISTINCT f.OrderID)                       AS TotalOrders,
    COUNT(DISTINCT f.CustomerKey)                   AS TotalActiveCustomers,
    SUM(f.Quantity)                                 AS TotalUnitsSold,
    ROUND(SUM(f.Sales), 2)                          AS TotalRevenue,
    ROUND(SUM(f.Profit), 2)                         AS TotalProfit,
    ROUND((SUM(f.Profit) / SUM(f.Sales)) * 100, 2)  AS OverallProfitMarginPct,
    ROUND(SUM(f.Sales) / COUNT(DISTINCT f.OrderID), 2) AS AverageOrderValue,
    ROUND(AVG(f.Discount) * 100, 2)                 AS AverageDiscountPct
FROM Fact_Sales f;

-- ----------------------------------------------------------------------------
-- KPI 2: Profitability Breakdown - Profitable vs Loss-Making Transactions
-- Demonstrates the hidden drag of negative-margin transactions.
-- ----------------------------------------------------------------------------
SELECT 
    CASE 
        WHEN f.Profit >= 0 THEN 'Profitable Transactions' 
        ELSE 'Loss-Making Transactions' 
    END                                             AS TransactionCategory,
    COUNT(*)                                        AS TransactionCount,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM Fact_Sales), 2) AS PctOfTotalTransactions,
    ROUND(SUM(f.Sales), 2)                          AS TotalSales,
    ROUND(SUM(f.Sales) * 100.0 / (SELECT SUM(Sales) FROM Fact_Sales), 2) AS PctOfTotalSales,
    ROUND(SUM(f.Profit), 2)                         AS TotalProfitOrLoss,
    ROUND((SUM(f.Profit) / SUM(f.Sales)) * 100, 2)  AS EffectiveMarginPct
FROM Fact_Sales f
GROUP BY 
    CASE WHEN f.Profit >= 0 THEN 'Profitable Transactions' ELSE 'Loss-Making Transactions' END;

-- ----------------------------------------------------------------------------
-- KPI 3: Annual Performance & Year-over-Year (YoY) Trajectory
-- Uses window functions LAG() to calculate YoY revenue and profit growth.
-- ----------------------------------------------------------------------------
WITH YearlySummary AS (
    SELECT 
        d.Year,
        COUNT(DISTINCT f.OrderID) AS OrderCount,
        ROUND(SUM(f.Sales), 2)    AS Revenue,
        ROUND(SUM(f.Profit), 2)   AS Profit,
        ROUND((SUM(f.Profit) / SUM(f.Sales)) * 100, 2) AS MarginPct
    FROM Fact_Sales f
    JOIN Dim_Date d ON f.OrderDateKey = d.DateKey
    GROUP BY d.Year
)
SELECT 
    Year,
    OrderCount,
    Revenue,
    ROUND(
        (Revenue - LAG(Revenue, 1) OVER (ORDER BY Year)) * 100.0 / 
        LAG(Revenue, 1) OVER (ORDER BY Year), 2
    ) AS YoY_RevenueGrowthPct,
    Profit,
    ROUND(
        (Profit - LAG(Profit, 1) OVER (ORDER BY Year)) * 100.0 / 
        NULLIF(LAG(Profit, 1) OVER (ORDER BY Year), 0), 2
    ) AS YoY_ProfitGrowthPct,
    MarginPct
FROM YearlySummary
ORDER BY Year;
