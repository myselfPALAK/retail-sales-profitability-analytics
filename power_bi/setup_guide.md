# Power BI Implementation & Setup Guide

This guide provides end-to-end instructions for loading the processed dimensional data into **Power BI Desktop**, configuring the Star Schema, applying the custom theme, and setting up all DAX measures.

---

## Prerequisites
1. **Power BI Desktop** (Free download from [powerbi.microsoft.com](https://powerbi.microsoft.com))
2. Processed CSV files located in `data/processed/`:
   - `fact_sales.csv`
   - `dim_products.csv`
   - `dim_customers.csv`
   - `dim_geography.csv`
   - `dim_date.csv`

---

## Step 1: Ingest Data into Power BI Desktop

1. Open Power BI Desktop.
2. Click **Get Data** -> **Text/CSV**.
3. Navigate to `data/processed/` and import each of the 5 CSV files:
   - `dim_customers.csv`
   - `dim_products.csv`
   - `dim_geography.csv`
   - `dim_date.csv`
   - `fact_sales.csv`
4. In the preview window for each file, click **Transform Data** (Power Query Editor).
5. Verify column data types:
   - `Fact_Sales[Sales]`, `[Profit]`, `[UnitPrice]`, `[ShippingCost]`: **Decimal Number**
   - `Fact_Sales[Discount]`, `[ProfitMargin]`: **Percentage / Decimal Number**
   - `Fact_Sales[Quantity]`: **Whole Number**
   - `Dim_Date[FullDate]`: **Date**
6. Click **Close & Apply**.

---

## Step 2: Establish Star Schema Relationships

Navigate to the **Model View** tab in Power BI (left sidebar) and configure the following 1-to-Many (`1:*`) single-directional relationships:

| From Table (Dimension) | From Column | To Table (Fact) | To Column | Cardinality | Cross Filter Direction |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **Dim_Date** | `DateKey` | **Fact_Sales** | `OrderDateKey` | One-to-Many (`1:*`) | Single |
| **Dim_Customer** | `CustomerKey` | **Fact_Sales** | `CustomerKey` | One-to-Many (`1:*`) | Single |
| **Dim_Product** | `ProductKey` | **Fact_Sales** | `ProductKey` | One-to-Many (`1:*`) | Single |
| **Dim_Geography** | `GeographyKey` | **Fact_Sales** | `GeographyKey` | One-to-Many (`1:*`) | Single |

> [!TIP]
> Ensure all relationships flow from Dimension to Fact. Hide the surrogate key columns (`*Key`) in the Fact table from the Report View to keep the field list clean.

---

## Step 3: Apply Custom Modern Executive Theme

1. In the Power BI ribbon, select **View** -> **Themes dropdown** -> **Browse for themes**.
2. Select `power_bi/theme/modern_executive_theme.json`.
3. The report canvas will immediately adopt the clean, modern color palette and typography.

---

## Step 4: Create Measure Tables & Add DAX Measures

1. In the **Home** tab, click **Enter Data**.
2. Name the table `_Measures` and click **Load**.
3. Right-click `_Measures` and select **New Measure**.
4. Open the files in `power_bi/dax_measures/` and paste each measure:
   - `01_core_kpis.dax` (Total Sales, Total Profit, Profit Margin %, AOV)
   - `02_time_intelligence.dax` (Sales YTD, SPLY, YoY Growth %)
   - `03_profitability_diagnostics.dax` (Loss Making Orders, High Discount Sales)
   - `04_dynamic_rankings.dax` (Rankings, Pareto 80/20, Status Colors)
5. Delete the default blank `Column1` from `_Measures`. The table will automatically move to the top of your Fields pane with a calculator icon!

---

## Step 5: Build Report Pages

Follow the detailed visual-by-visual layout guide in:
[dashboard_design_specs.md](file:///Users/PALAK/.gemini/antigravity/scratch/retail-sales-profitability-analytics/power_bi/wireframes/dashboard_design_specs.md)

1. **Page 1: Executive Overview** (KPI cards ribbon, Monthly Trend line/column chart, Category split)
2. **Page 2: Product & Category Diagnostics** (Subcategory bar chart, Margin vs Discount scatter plot)
3. **Page 3: Regional & Geographic Deep Dive** (State-level map, Central region diagnostic)
4. **Page 4: Strategic Scenario & Discount Simulator** (What-if parameter slider)

---

## Step 6: Publish or Share

1. Click **File** -> **Save As** -> `Retail_Sales_and_Profitability_Analytics.pbix`.
2. (Optional) Click **Publish** to publish to your Power BI Service workspace and generate a public web link or PDF export.
3. Take screenshots of each report page and save them to `docs/screenshots/` to display in your GitHub README!
