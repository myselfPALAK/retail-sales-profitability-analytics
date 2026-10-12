# Resume Bullet Points & Interview Guide

Use these pre-crafted bullet points and talking points on your resume, LinkedIn profile, and during technical/behavioral interviews.

---

## 1. Resume Bullet Points

### Option A: For Data Analyst / BI Analyst Roles
- **Retail Sales & Profitability Analytics System | SQL, Power BI, DAX, Python**
  - Architected a Kimball Star Schema data model across 9,994 transactions and \$5.89M in retail sales, engineering 4 dimension tables and a centralized sales fact table to accelerate analytical query performance.
  - Authored an advanced SQL analytics suite utilizing CTEs, window functions (`LAG`, `NTILE`, `RANK`), and rolling averages to diagnose regional margin leaks and customer RFM behavioral segments.
  - Developed an interactive 4-page Power BI dashboard with 25+ custom DAX measures (Time Intelligence, YoY growth, and Pareto 80/20 analysis) isolating critical margin drain in Furniture (-\$348K) and the Central Region (4.8% margin vs 14.4% in South).
  - Designed an executive What-If discount sensitivity model, delivering actionable recommendations to cap promotional discounts at 20% and projecting an annual profit recovery of **+\$48,500 (+76 bps margin uplift)**.

### Option B: For Analytics Engineer / Business Analyst Roles
- **Retail Sales & Profitability Optimization Engine | SQL, Star Schema, DAX, Power BI**
  - Spearheaded end-to-end analytics workflow from raw retail transactional data ingestion to executive BI dashboard delivery, modeling dimensional tables and establishing referential integrity.
  - Discovered root cause of Texas market underperformance (-\$25.4K net loss) by cross-analyzing discount elasticity against freight logistics and product cost structures.
  - Implemented automated SQL benchmark test suite achieving 100% test pass rate across 43 complex queries with sub-30ms execution times.
  - Published comprehensive executive strategy memo featuring a 90-day phased roadmap, sales commission restructuring, and product bundling strategies presented to C-level stakeholders.

---

## 2. LinkedIn Featured Project Summary

**Project Title:** Retail Sales & Profitability Analytics: Uncovering Margin Leakage with SQL & Power BI  
**Tech Stack:** SQL, Power BI Desktop, DAX, Kimball Dimensional Modeling, Python, Chart.js  

**Overview:**  
Built an end-to-end retail business intelligence project analyzing \$5.89M in sales across 4 fiscal years to answer a critical commercial question: *Why does top-line sales growth fail to translate into bottom-line profit?*

**Key Accomplishments:**
- Built a Kimball Star Schema with 1 Fact table (`Fact_Sales`) and 4 Dimensions (`Dim_Product`, `Dim_Customer`, `Dim_Geography`, `Dim_Date`).
- Formulated 25+ DAX measures including Time Intelligence (YTD, SPLY, YoY %), Pareto rankings, and discount leakage metrics.
- Identified that discounts exceeding 20% caused a tipping point where 68%+ of transactions became cash negative, particularly in Tables (-\$340.6K loss) and the Central region.
- Simulated a discount-cap scenario projecting **+\$48.5K net profit recovery**.

---

## 3. STAR Interview Talking Points

### Question: *"Tell me about a data analytics project where you identified a business problem and provided actionable recommendations."*

**Situation:**  
*"In my Retail Sales and Profitability Analytics project, I analyzed four years of transactional data representing nearly 10,000 orders and \$5.9 million in revenue. While gross revenue was growing at over 22% annually, operating profit margins were lagging at 10.99%, well below the corporate benchmark of 15%."*

**Task:**  
*"My objective was to build a scalable dimensional data model, develop an interactive Power BI executive dashboard, and perform deep-dive SQL diagnostics to uncover where profitability was leaking and recommend corrective commercial actions."*

**Action:**  
*"I first designed a Kimball-style Star Schema with four dimension tables and one fact table. Using advanced SQL—specifically window functions like `LAG` for Month-over-Month growth, `NTILE` for RFM customer segmentation, and rolling averages—I analyzed performance across product categories, discount tiers, and geographies.*  
*In Power BI, I engineered over 25 DAX measures including Time Intelligence (YTD, SPLY) and diagnostic measures for loss-making orders.*  
*The analysis uncovered two major findings: First, the Tables subcategory was bleeding \$340,000 in losses due to unmanaged discounts averaging 25%. Second, the Central region, especially Texas, was delivering a meager 4.8% margin compared to 14.4% in the South due to sales reps over-relying on price cuts."*

**Result:**  
*"I designed a SQL What-If simulation modeling the effect of a hard 20% cap on promotional discounts. The simulation demonstrated an immediate annual profit recovery opportunity of \$48,500 with a 76-basis-point margin expansion. I packaged these insights into a 90-day executive roadmap recommending automated discount controls, commission restructuring based on gross margin contribution, and accessory bundling."*

---

## 4. Technical Follow-Up Q&A Prep

#### Q: *"Why did you choose a Star Schema instead of querying the flat denormalized table?"*
**A:**  
*"A Star Schema separates business dimensions (Customers, Products, Geography, Date) from numerical transaction facts. In Power BI and relational databases, this drastically reduces data redundancy, optimizes columnar compression (VertiPaq engine), avoids many-to-many relationship pitfalls, and simplifies DAX formulas through clean 1-to-Many single-directional filter propagation."*

#### Q: *"What was the most challenging DAX measure you wrote and why?"*
**A:**  
*"Writing the dynamic Pareto cumulative sales percentage measure. It required utilizing `ADDCOLUMNS`, `ALLSELECTED`, and `SUMX` with a filter condition comparing each item's sales against the current evaluation context to calculate the running cumulative revenue share dynamically across any selected filter or slicer."*

#### Q: *"How did you handle the difference between positive revenue and negative profit in your SQL models?"*
**A:**  
*"In SQL, I created conditional aggregations with `CASE WHEN Profit < 0` to segment transactions into profitable vs loss-making cohorts. This allowed me to compute loss rates, loss-making revenue share, and evaluate profit elasticity across discrete discount buckets (0%, 1-15%, 16-25%, 26-40%, 40%+)."*
