-- ============================================================================
-- Project 2: Retail Sales and Profitability Analytics
-- Script 07: Time Series Trends, MoM Growth & Moving Averages
-- ============================================================================
-- Description:
--   Advanced SQL time-series analytics demonstrating window functions:
--   - Monthly revenue, profit, and margin progression
--   - Month-over-Month (MoM) Revenue & Profit % Growth (LAG)
--   - 3-Month Rolling / Moving Average Revenue & Profit
--   - Quarterly Seasonality patterns across all fiscal years
--   - Weekday vs Weekend shopping behavior
-- ============================================================================

-- ----------------------------------------------------------------------------
-- Analysis 1: Monthly Trend, MoM Growth & 3-Month Moving Average
-- ----------------------------------------------------------------------------
WITH MonthlyBase AS (
    SELECT 
        d.Year,
        d.Month,
        d.MonthName,
        d.MonthYear,
        COUNT(DISTINCT f.OrderID)   AS OrdersCount,
        ROUND(SUM(f.Sales), 2)      AS MonthlySales,
        ROUND(SUM(f.Profit), 2)     AS MonthlyProfit,
        ROUND((SUM(f.Profit) / SUM(f.Sales)) * 100, 2) AS MonthlyMarginPct
    FROM Fact_Sales f
    JOIN Dim_Date d ON f.OrderDateKey = d.DateKey
    GROUP BY d.Year, d.Month, d.MonthName, d.MonthYear
)
SELECT 
    Year,
    Month,
    MonthYear,
    OrdersCount,
    MonthlySales,
    -- Month-over-Month Sales Growth
    ROUND(
        (MonthlySales - LAG(MonthlySales, 1) OVER (ORDER BY Year, Month)) * 100.0 / 
        NULLIF(LAG(MonthlySales, 1) OVER (ORDER BY Year, Month), 0), 
        2
    ) AS MoM_SalesGrowthPct,
    MonthlyProfit,
    -- Month-over-Month Profit Growth
    ROUND(
        (MonthlyProfit - LAG(MonthlyProfit, 1) OVER (ORDER BY Year, Month)) * 100.0 / 
        NULLIF(ABS(LAG(MonthlyProfit, 1) OVER (ORDER BY Year, Month)), 0), 
        2
    ) AS MoM_ProfitGrowthPct,
    MonthlyMarginPct,
    -- 3-Month Rolling Average Revenue
    ROUND(
        AVG(MonthlySales) OVER (
            ORDER BY Year, Month 
            ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
        ), 
        2
    ) AS Rolling3MonthAvgSales,
    -- 3-Month Rolling Average Profit
    ROUND(
        AVG(MonthlyProfit) OVER (
            ORDER BY Year, Month 
            ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
        ), 
        2
    ) AS Rolling3MonthAvgProfit
FROM MonthlyBase
ORDER BY Year, Month;

-- ----------------------------------------------------------------------------
-- Analysis 2: Quarterly Seasonality Comparison
-- Uncovers recurring seasonal peaks (e.g. Q4 holiday surge)
-- ----------------------------------------------------------------------------
SELECT 
    d.Quarter,
    COUNT(DISTINCT f.OrderID)                       AS TotalQuarterOrders,
    ROUND(SUM(f.Sales), 2)                          AS TotalQuarterSales,
    ROUND(SUM(f.Sales) * 100.0 / (SELECT SUM(Sales) FROM Fact_Sales), 2) AS RevenueSharePct,
    ROUND(SUM(f.Profit), 2)                         AS TotalQuarterProfit,
    ROUND((SUM(f.Profit) / SUM(f.Sales)) * 100, 2)  AS QuarterMarginPct,
    ROUND(AVG(f.Discount) * 100, 1)                 AS AvgQuarterDiscountPct
FROM Fact_Sales f
JOIN Dim_Date d ON f.OrderDateKey = d.DateKey
GROUP BY d.Quarter
ORDER BY d.Quarter;

-- ----------------------------------------------------------------------------
-- Analysis 3: Day-of-Week & Weekend vs Weekday Performance
-- ----------------------------------------------------------------------------
SELECT 
    d.DayOfWeek,
    d.DayOfWeekNumber,
    CASE WHEN d.IsWeekend = 1 THEN 'Weekend' ELSE 'Weekday' END AS DayType,
    COUNT(DISTINCT f.OrderID)                       AS OrderVolume,
    ROUND(SUM(f.Sales), 2)                          AS TotalSales,
    ROUND(SUM(f.Profit), 2)                         AS TotalProfit,
    ROUND((SUM(f.Profit) / SUM(f.Sales)) * 100, 2)  AS MarginPct,
    ROUND(SUM(f.Sales) / COUNT(DISTINCT f.OrderID), 2) AS AverageOrderValue
FROM Fact_Sales f
JOIN Dim_Date d ON f.OrderDateKey = d.DateKey
GROUP BY d.DayOfWeek, d.DayOfWeekNumber, d.IsWeekend
ORDER BY d.DayOfWeekNumber;
