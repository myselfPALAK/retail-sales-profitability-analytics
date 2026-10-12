# Power BI Dashboard Visual Architecture & Wireframe Specifications

This document outlines the exact visual layout, interaction flows, DAX measure assignments, and formatting specifications for building the 4-page Power BI report.

---

## Global Page Specifications
- **Canvas Size**: 16:9 Widescreen (1280 x 720 px)
- **Theme**: `power_bi/theme/modern_executive_theme.json`
- **Header Banner**: 
  - Dark Navy fill (`#0F172A`)
  - Title: **Retail Sales & Profitability Analytics | Executive Dashboard**
  - Right-side Global Slicers: `Dim_Date[Year]`, `Dim_Customer[Segment]`, `Dim_Geography[Region]`

---

## Page 1: Executive Overview
**Objective**: Deliver high-level financial health indicators, annual trajectory, and portfolio mix at a glance.

```
+-------------------------------------------------------------------------------------------------------+
|  [ HEADER: Retail Sales & Profitability Analytics ]       [ Year: All | Segment: All | Region: All ]  |
+-------------------------------------------------------------------------------------------------------+
|  [ KPI 1: Total Sales ]  |  [ KPI 2: Total Profit ]  |  [ KPI 3: Margin % ]  |  [ KPI 4: Total Orders ]|
|  $5.89M (▲ 22.4% YoY)    |  $647.6K (▲ 18.2% YoY)   |  10.99% (▲ 0.4 pts)   |  9,994 Orders           |
+-------------------------------------------------------+-----------------------------------------------+
|  VISUAL 1: Revenue & Profit Monthly Trajectory        |  VISUAL 2: Regional Performance Matrix        |
|  - Type: Line and Clustered Column Chart             |  - Type: Donut Chart / Horizontal Bar         |
|  - Shared Axis: Dim_Date[MonthYear]                  |  - Values: [Total Sales], [Total Profit]      |
|  - Column: [Total Sales]                             |  - Legend: Dim_Geography[Region]             |
|  - Line: [Profit Margin %] (Secondary Y-Axis)        |  - Tooltip: Margin %, Avg Discount %          |
+-------------------------------------------------------+-----------------------------------------------+
|  VISUAL 3: Sales by Product Category                 |  VISUAL 4: Loss-Making Order Alert Card       |
|  - Type: 100% Stacked Bar Chart                      |  - Metric: [Loss Making Transactions]         |
|  - Axis: Dim_Product[Category]                       |  - Sub-label: [Loss Making Orders Ratio %]    |
|  - Value: [Total Sales], [Total Profit]              |  - Visual: Red warning banner                 |
+-------------------------------------------------------------------------------------------------------+
```

### Visual Configuration:
1. **Top KPI Ribbon (Cards)**:
   - Card 1: `[Total Sales]` with callout subtitle `[YoY Sales Growth %]`
   - Card 2: `[Total Profit]` with callout subtitle `[YoY Profit Growth %]`
   - Card 3: `[Profit Margin %]` with conditional font color (`[Margin KPI Status Color]`)
   - Card 4: `[Average Order Value (AOV)]`
2. **Visual 1 (Line & Column Chart)**:
   - X-Axis: `Dim_Date[FullDate]` aggregated by Month.
   - Column Values: `[Total Sales]` (Deep Blue `#2563EB`).
   - Line Values: `[Profit Margin %]` (Emerald `#10B981`).
3. **Visual 2 (Regional Breakdown)**:
   - Category: `Dim_Geography[Region]`
   - Values: `[Total Sales]`, `[Total Profit]`, `[Profit Margin %]`

---

## Page 2: Product & Category Diagnostics
**Objective**: Identify value champions and unmask hidden loss-making product categories and sub-categories.

```
+-------------------------------------------------------------------------------------------------------+
|  [ HEADER: Product & Category Diagnostics ]                                                            |
+-------------------------------------------------------------------------------------------------------+
|  VISUAL 1: Sub-Category Profitability Spectrum         |  VISUAL 2: Margin % vs Avg Discount Scatter  |
|  - Type: Horizontal Clustered Bar Chart               |  - Type: Scatter Plot                         |
|  - Y-Axis: Dim_Product[SubCategory]                   |  - X-Axis: [Average Discount %]               |
|  - X-Axis: [Total Profit]                             |  - Y-Axis: [Profit Margin %]                  |
|  - Conditional Color: Green (Positive), Red (Negative)|  - Size: [Total Sales]                        |
|    * Note: Tables & Supplies clearly in red zone      |  - Details: Dim_Product[SubCategory]          |
+-------------------------------------------------------+-----------------------------------------------+
|  VISUAL 3: Top 10 Value Champions (Profitable)        |  VISUAL 4: Top 10 Margin Drainers (Loss-makers)|
|  - Type: Table Visual                                 |  - Type: Table Visual                         |
|  - Columns: Product Name, Category, Sales, Profit     |  - Filter: Top 10 by [Total Profit] Bottom N  |
+-------------------------------------------------------------------------------------------------------+
```

### Key Insights Highlighted on this Page:
- **Tables** generates heavy revenue but produces severe negative margins due to excessive discounts (>30%).
- **Copiers** and **Phones** generate high revenue with 35-45% profit margins.

---

## Page 3: Regional & Geographic Deep Dive
**Objective**: Drill down into regional profitability discrepancies, specifically isolating the Central region margin leak.

```
+-------------------------------------------------------------------------------------------------------+
|  [ HEADER: Regional & Geographic Deep Dive ]                                                          |
+-------------------------------------------------------------------------------------------------------+
|  VISUAL 1: State Profitability Map                    |  VISUAL 2: Central Region Margin Erosion      |
|  - Type: Filled Map / Shape Map                       |  - Type: Clustered Column Chart               |
|  - Location: Dim_Geography[State]                     |  - Axis: SubCategory                          |
|  - Color Saturation: [Profit Margin %]                |  - Compare: Central Margin vs National Avg    |
+-------------------------------------------------------+-----------------------------------------------+
|  VISUAL 3: State-Level Profit & Loss League Table                                                     |
|  - Type: Matrix Visual                                                                                |
|  - Rows: Region -> State -> City                                                                      |
|  - Values: [Total Sales], [Total Profit], [Profit Margin %], [Average Discount %]                     |
|  - Formatting: Data bars on Sales, Color scale on Margin %                                            |
+-------------------------------------------------------------------------------------------------------+
```

---

## Page 4: Strategic What-If & Scenario Simulation
**Objective**: Model executive scenarios and calculate profit uplift under discount capping policies.

```
+-------------------------------------------------------------------------------------------------------+
|  [ HEADER: Strategic Scenario & Discount Policy Simulator ]                                          |
+-------------------------------------------------------------------------------------------------------+
|  SLICER: Discount Policy Cap Slider (0% to 50%, Default: 20% max cap)                                 |
+-------------------------------------------------------+-----------------------------------------------+
|  CARD 1: Current Profit                               |  CARD 2: Simulated Profit Under Cap           |
|  $647,592                                             |  $696,092 (+ $48,500 Recovery)                |
+-------------------------------------------------------+-----------------------------------------------+
|  VISUAL 1: Discount Sensitivity Curve                 |  VISUAL 2: Sub-Category Recovery Impact      |
|  - X-Axis: Discount Tier (<15%, 16-25%, 26-40%, >40%)|  - Tornado / Waterfall Chart                  |
|  - Bars: Sales Volume                                 |  - Recovered margin contribution by sub-cat   |
|  - Line: Effective Margin %                           |                                               |
+-------------------------------------------------------------------------------------------------------+
```
