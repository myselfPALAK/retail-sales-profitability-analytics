-- ============================================================================
-- Project 2: Retail Sales and Profitability Analytics
-- Script 06: Customer Segmentation & RFM (Recency, Frequency, Monetary) Analysis
-- ============================================================================
-- Description:
--   Unlocks customer lifetime value and behavior patterns:
--   - Performance by Market Segment (Consumer, Corporate, Home Office)
--   - Full RFM Segmentation using NTILE window ranking functions
--   - Customer Concentration & Pareto Analysis (80/20 Rule)
--   - Top 10 High-Value VIP Customers
-- ============================================================================

-- ----------------------------------------------------------------------------
-- Analysis 1: Performance by Customer Market Segment
-- ----------------------------------------------------------------------------
SELECT 
    c.Segment,
    COUNT(DISTINCT c.CustomerID)                    AS TotalCustomers,
    COUNT(DISTINCT f.OrderID)                       AS TotalOrders,
    ROUND(COUNT(DISTINCT f.OrderID) * 1.0 / COUNT(DISTINCT c.CustomerID), 2) AS OrdersPerCustomer,
    ROUND(SUM(f.Sales), 2)                          AS TotalRevenue,
    ROUND(SUM(f.Profit), 2)                         AS TotalProfit,
    ROUND((SUM(f.Profit) / SUM(f.Sales)) * 100, 2)  AS SegmentProfitMarginPct,
    ROUND(SUM(f.Sales) / COUNT(DISTINCT f.OrderID), 2) AS AverageOrderValue,
    ROUND(SUM(f.Sales) / COUNT(DISTINCT c.CustomerID), 2) AS AverageCustomerValue
FROM Fact_Sales f
JOIN Dim_Customer c ON f.CustomerKey = c.CustomerKey
GROUP BY c.Segment
ORDER BY TotalRevenue DESC;

-- ----------------------------------------------------------------------------
-- Analysis 2: RFM Customer Behavioral Segmentation
-- Measures:
--   - Recency: Days since last order relative to the maximum dataset date
--   - Frequency: Total distinct orders placed
--   - Monetary: Total lifetime revenue spend
-- ----------------------------------------------------------------------------
WITH CustomerAggs AS (
    SELECT 
        c.CustomerKey,
        c.CustomerID,
        c.CustomerName,
        c.Segment,
        MAX(d.FullDate) AS LastOrderDate,
        COUNT(DISTINCT f.OrderID) AS Frequency,
        ROUND(SUM(f.Sales), 2) AS Monetary,
        ROUND(SUM(f.Profit), 2) AS LifetimeProfit
    FROM Fact_Sales f
    JOIN Dim_Customer c ON f.CustomerKey = c.CustomerKey
    JOIN Dim_Date d     ON f.OrderDateKey = d.DateKey
    GROUP BY c.CustomerKey, c.CustomerID, c.CustomerName, c.Segment
),
ReferenceDate AS (
    SELECT MAX(FullDate) AS MaxDatasetDate FROM Dim_Date
),
RFM_Calculated AS (
    SELECT 
        ca.*,
        -- Days since last order (using Julian day diff in SQLite or DATEDIFF in T-SQL)
        CAST((julianday((SELECT MaxDatasetDate FROM ReferenceDate)) - julianday(ca.LastOrderDate)) AS INTEGER) AS RecencyDays,
        NTILE(5) OVER (ORDER BY (julianday((SELECT MaxDatasetDate FROM ReferenceDate)) - julianday(ca.LastOrderDate)) DESC) AS R_Score,
        NTILE(5) OVER (ORDER BY ca.Frequency ASC) AS F_Score,
        NTILE(5) OVER (ORDER BY ca.Monetary ASC) AS M_Score
    FROM CustomerAggs ca
),
RFM_Tagged AS (
    SELECT 
        *,
        (R_Score * 100 + F_Score * 10 + M_Score) AS RFM_Cell,
        CASE 
            WHEN R_Score >= 4 AND F_Score >= 4 AND M_Score >= 4 THEN 'Champions / VIP'
            WHEN R_Score >= 3 AND F_Score >= 3 AND M_Score >= 3 THEN 'Loyal Customers'
            WHEN R_Score >= 3 AND F_Score <= 2 AND M_Score >= 3 THEN 'Potential Loyalists'
            WHEN R_Score >= 4 AND F_Score <= 2                  THEN 'Recent New Customers'
            WHEN R_Score <= 2 AND F_Score >= 3                  THEN 'At Risk / Need Attention'
            WHEN R_Score <= 2 AND F_Score <= 2 AND M_Score >= 3 THEN 'Hibernating High Spenders'
            ELSE 'Lost / Churned'
        END AS CustomerSegmentTier
    FROM RFM_Calculated
)
SELECT 
    CustomerSegmentTier,
    COUNT(*)                                        AS CustomerCount,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM Dim_Customer), 1) AS PctOfCustomerBase,
    ROUND(SUM(Monetary), 2)                         AS TotalRevenueSpend,
    ROUND(SUM(Monetary) * 100.0 / (SELECT SUM(Sales) FROM Fact_Sales), 1) AS RevenueSharePct,
    ROUND(SUM(LifetimeProfit), 2)                   AS TotalProfitContribution,
    ROUND(AVG(RecencyDays), 0)                      AS AvgRecencyDays,
    ROUND(AVG(Frequency), 1)                        AS AvgOrderFrequency,
    ROUND(AVG(Monetary), 2)                         AS AvgCustomerSpend
FROM RFM_Tagged
GROUP BY CustomerSegmentTier
ORDER BY TotalRevenueSpend DESC;

-- ----------------------------------------------------------------------------
-- Analysis 3: Pareto Principle (80/20 Rule) Customer Concentration
-- ----------------------------------------------------------------------------
WITH CustomerSpend AS (
    SELECT 
        c.CustomerID,
        SUM(f.Sales) AS TotalSpend,
        ROW_NUMBER() OVER (ORDER BY SUM(f.Sales) DESC) AS SpendRank,
        COUNT(*) OVER () AS TotalCustomerCount,
        SUM(SUM(f.Sales)) OVER () AS EnterpriseTotalSpend
    FROM Fact_Sales f
    JOIN Dim_Customer c ON f.CustomerKey = c.CustomerKey
    GROUP BY c.CustomerID
),
CumulativeShare AS (
    SELECT 
        CustomerID,
        TotalSpend,
        SpendRank,
        TotalCustomerCount,
        ROUND(SpendRank * 100.0 / TotalCustomerCount, 1) AS PctOfTotalCustomers,
        SUM(TotalSpend) OVER (ORDER BY SpendRank) AS RunningTotalSpend,
        ROUND(SUM(TotalSpend) OVER (ORDER BY SpendRank) * 100.0 / EnterpriseTotalSpend, 2) AS CumulativeRevenuePct
    FROM CustomerSpend
)
SELECT 
    CASE 
        WHEN PctOfTotalCustomers <= 20.0 THEN 'Top 20% Customers (High Impact)'
        WHEN PctOfTotalCustomers <= 50.0 THEN 'Next 30% Customers (Mid Tier)'
        ELSE 'Bottom 50% Customers (Long Tail)'
    END AS CustomerTier,
    COUNT(*) AS CustomerCount,
    ROUND(SUM(TotalSpend), 2) AS GroupRevenue,
    ROUND(SUM(TotalSpend) * 100.0 / (SELECT EnterpriseTotalSpend FROM CustomerSpend LIMIT 1), 2) AS RevenueContributionPct
FROM CumulativeShare
GROUP BY 
    CASE 
        WHEN PctOfTotalCustomers <= 20.0 THEN 'Top 20% Customers (High Impact)'
        WHEN PctOfTotalCustomers <= 50.0 THEN 'Next 30% Customers (Mid Tier)'
        ELSE 'Bottom 50% Customers (Long Tail)'
    END
ORDER BY GroupRevenue DESC;
