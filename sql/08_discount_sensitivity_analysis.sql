-- ============================================================================
-- Project 2: Retail Sales and Profitability Analytics
-- Script 08: Discount Sensitivity & Elasticity Diagnostics
-- ============================================================================
-- Description:
--   Root cause diagnostic of retail margin erosion:
--   - Performance by Discount Tiers / Brackets
--   - Determining the exact 'Point of Negative Return' (Loss tipping point)
--   - SQL What-If Simulation: Projected profit recovery by capping discounts at 20%
--   - Category-level elasticity to promotional discounting
-- ============================================================================

-- ----------------------------------------------------------------------------
-- Analysis 1: Performance by Discount Brackets
-- Demonstrates how margin percentage evaporates as discount scales.
-- ----------------------------------------------------------------------------
SELECT 
    CASE
        WHEN f.Discount = 0.00 THEN 'Tier 1: 0% (Full Price)'
        WHEN f.Discount <= 0.15 THEN 'Tier 2: 1% - 15% (Low Promo)'
        WHEN f.Discount <= 0.25 THEN 'Tier 3: 16% - 25% (Moderate Promo)'
        WHEN f.Discount <= 0.40 THEN 'Tier 4: 26% - 40% (Aggressive Promo)'
        ELSE 'Tier 5: 41%+ (Deep Clearance)'
    END AS DiscountTier,
    COUNT(*)                                        AS TransactionCount,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM Fact_Sales), 1) AS PctOfTransactions,
    ROUND(SUM(f.Sales), 2)                          AS TotalSalesRevenue,
    ROUND(SUM(f.Profit), 2)                         AS TotalProfit,
    ROUND((SUM(f.Profit) / SUM(f.Sales)) * 100, 2)  AS EffectiveMarginPct,
    SUM(CASE WHEN f.Profit < 0 THEN 1 ELSE 0 END)   AS LossMakingOrdersCount,
    ROUND(
        SUM(CASE WHEN f.Profit < 0 THEN 1.0 ELSE 0.0 END) * 100.0 / COUNT(*), 
        1
    ) AS LossRatePct
FROM Fact_Sales f
GROUP BY 
    CASE
        WHEN f.Discount = 0.00 THEN 'Tier 1: 0% (Full Price)'
        WHEN f.Discount <= 0.15 THEN 'Tier 2: 1% - 15% (Low Promo)'
        WHEN f.Discount <= 0.25 THEN 'Tier 3: 16% - 25% (Moderate Promo)'
        WHEN f.Discount <= 0.40 THEN 'Tier 4: 26% - 40% (Aggressive Promo)'
        ELSE 'Tier 5: 41%+ (Deep Clearance)'
    END
ORDER BY TotalProfit DESC;

-- ----------------------------------------------------------------------------
-- Analysis 2: Granular Discount Level Profitability (Finding the Tipping Point)
-- Evaluates margin at each discrete discount increment.
-- ----------------------------------------------------------------------------
SELECT 
    ROUND(f.Discount * 100, 0)                      AS DiscountPct,
    COUNT(*)                                        AS TotalTransactions,
    ROUND(SUM(f.Sales), 2)                          AS TotalSales,
    ROUND(SUM(f.Profit), 2)                         AS TotalProfit,
    ROUND((SUM(f.Profit) / SUM(f.Sales)) * 100, 2)  AS MarginPct,
    CASE 
        WHEN (SUM(f.Profit) / SUM(f.Sales)) < 0 THEN 'LOSS-MAKING ZONE'
        WHEN (SUM(f.Profit) / SUM(f.Sales)) < 0.10 THEN 'AT-RISK / THIN MARGIN'
        ELSE 'PROFITABLE ZONE'
    END AS MarginHealthStatus
FROM Fact_Sales f
GROUP BY ROUND(f.Discount * 100, 0)
ORDER BY DiscountPct ASC;

-- ----------------------------------------------------------------------------
-- Analysis 3: What-If Simulation - Capping Discounts at 20% Maximum
-- Models the business impact if discounts exceeding 20% were restricted to 20%.
-- ----------------------------------------------------------------------------
WITH BaselineVsSimulated AS (
    SELECT 
        f.SalesID,
        f.Sales     AS ActualSales,
        f.Profit    AS ActualProfit,
        f.Discount  AS ActualDiscount,
        -- If discount > 0.20, recalculate sales at 0.20 discount
        CASE 
            WHEN f.Discount > 0.20 THEN ROUND(f.Quantity * f.UnitPrice * 0.80, 2)
            ELSE f.Sales
        END AS SimulatedSales,
        -- Recalculate profit: SimulatedSales - Estimated Cost
        -- Estimated Cost = (ActualSales - ActualProfit)
        CASE 
            WHEN f.Discount > 0.20 THEN ROUND((f.Quantity * f.UnitPrice * 0.80) - (f.Sales - f.Profit), 2)
            ELSE f.Profit
        END AS SimulatedProfit
    FROM Fact_Sales f
)
SELECT 
    ROUND(SUM(ActualSales), 2)                          AS ActualTotalRevenue,
    ROUND(SUM(SimulatedSales), 2)                       AS SimulatedTotalRevenue,
    ROUND(SUM(SimulatedSales) - SUM(ActualSales), 2)    AS ProjectedRevenueUplift,
    ROUND(SUM(ActualProfit), 2)                         AS ActualTotalProfit,
    ROUND(SUM(SimulatedProfit), 2)                      AS SimulatedTotalProfit,
    ROUND(SUM(SimulatedProfit) - SUM(ActualProfit), 2)  AS NetProfitRecoveryOpportunity,
    ROUND((SUM(ActualProfit) / SUM(ActualSales)) * 100, 2) AS ActualMarginPct,
    ROUND((SUM(SimulatedProfit) / SUM(SimulatedSales)) * 100, 2) AS SimulatedMarginPct,
    ROUND(
        ((SUM(SimulatedProfit) / SUM(SimulatedSales)) - 
         (SUM(ActualProfit) / SUM(ActualSales))) * 100, 
        2
    ) AS MarginExpansionPercentagePoints
FROM BaselineVsSimulated;

-- ----------------------------------------------------------------------------
-- Analysis 4: Category Sensitivity to Discounting
-- Identifies which product categories suffer the highest margin destruction
-- when discounted.
-- ----------------------------------------------------------------------------
SELECT 
    p.Category,
    -- Full Price Margins (0% Discount)
    ROUND(
        SUM(CASE WHEN f.Discount = 0 THEN f.Profit ELSE 0 END) * 100.0 / 
        NULLIF(SUM(CASE WHEN f.Discount = 0 THEN f.Sales ELSE 0 END), 0), 
        2
    ) AS FullPriceMarginPct,
    -- Discounted Margins (> 0% Discount)
    ROUND(
        SUM(CASE WHEN f.Discount > 0 THEN f.Profit ELSE 0 END) * 100.0 / 
        NULLIF(SUM(CASE WHEN f.Discount > 0 THEN f.Sales ELSE 0 END), 0), 
        2
    ) AS DiscountedMarginPct,
    -- Margin Drop (Sensitivity)
    ROUND(
        (SUM(CASE WHEN f.Discount = 0 THEN f.Profit ELSE 0 END) * 100.0 / 
         NULLIF(SUM(CASE WHEN f.Discount = 0 THEN f.Sales ELSE 0 END), 0)) -
        (SUM(CASE WHEN f.Discount > 0 THEN f.Profit ELSE 0 END) * 100.0 / 
         NULLIF(SUM(CASE WHEN f.Discount > 0 THEN f.Sales ELSE 0 END), 0)),
        2
    ) AS MarginDropPercentagePoints
FROM Fact_Sales f
JOIN Dim_Product p ON f.ProductKey = p.ProductKey
GROUP BY p.Category
ORDER BY MarginDropPercentagePoints DESC;
