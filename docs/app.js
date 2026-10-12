/**
 * Retail Sales & Profitability Analytics - Interactive Web Dashboard
 * Fully client-side interactive BI Dashboard using Chart.js
 */

let globalData = null;
let charts = {};

// Helper: Format currency
function formatCurrency(val) {
  if (val === null || val === undefined) return "$0";
  return new Intl.NumberFormat("en-US", {
    style: "currency",
    currency: "USD",
    maximumFractionDigits: 0
  }).format(val);
}

// Helper: Format percentage
function formatPct(val) {
  if (val === null || val === undefined) return "0.0%";
  return `${Number(val).toFixed(2)}%`;
}

// Chart.js Default Dark Theme Setup
Chart.defaults.color = "#94a3b8";
Chart.defaults.font.family = "-apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif";
Chart.defaults.plugins.tooltip.backgroundColor = "#0f172a";
Chart.defaults.plugins.tooltip.borderColor = "#334155";
Chart.defaults.plugins.tooltip.borderWidth = 1;
Chart.defaults.plugins.tooltip.titleColor = "#f8fafc";
Chart.defaults.plugins.tooltip.bodyColor = "#cbd5e1";
Chart.defaults.plugins.tooltip.padding = 10;

// Initialize Dashboard
document.addEventListener("DOMContentLoaded", async () => {
  try {
    const res = await fetch("data.json");
    if (!res.ok) throw new Error("Network response not ok");
    globalData = await res.json();
    initDashboard(globalData);
  } catch (err) {
    console.warn("Could not load data.json via fetch (likely local file:// protocol). Attempting fallback payload.");
    // Fallback payload if browser blocks local fetch()
    initDashboardWithEmbeddedData();
  }
});

function initDashboard(data) {
  setupFilterListeners();
  updateKPIs(data.kpis);
  renderMonthlyChart(data.monthly_trend);
  renderCategoryChart(data.category_performance);
  renderSubCategoryChart(data.subcategory_performance);
  renderRegionalChart(data.regional_performance);
  renderDiscountSensitivityChart(data.discount_sensitivity);
  renderDiagnosticTable(data.subcategory_performance);
}

function updateKPIs(kpis) {
  document.getElementById("kpi-sales").innerText = formatCurrency(kpis.total_sales);
  document.getElementById("kpi-profit").innerText = formatCurrency(kpis.total_profit);
  
  const marginEl = document.getElementById("kpi-margin");
  marginEl.innerText = formatPct(kpis.overall_margin_pct);
  if (kpis.overall_margin_pct < 8) {
    marginEl.className = "kpi-value text-red";
  } else if (kpis.overall_margin_pct < 12) {
    marginEl.className = "kpi-value text-amber";
  } else {
    marginEl.className = "kpi-value text-green";
  }

  document.getElementById("kpi-orders").innerText = Number(kpis.total_orders).toLocaleString();
  document.getElementById("kpi-discount").innerText = formatPct(kpis.avg_discount_pct);
}

// 1. Monthly Revenue & Profit Chart (Combo: Bar + Line)
function renderMonthlyChart(monthlyTrend) {
  const ctx = document.getElementById("chart-monthly").getContext("2d");
  
  // Aggregate to 12 months or sample evenly if 48 months
  // Display latest 18 months for crispness
  const slice = monthlyTrend.slice(-18);
  const labels = slice.map(d => d.month);
  const sales = slice.map(d => d.sales);
  const margins = slice.map(d => d.margin_pct);

  charts.monthly = new Chart(ctx, {
    type: "bar",
    data: {
      labels: labels,
      datasets: [
        {
          label: "Sales ($)",
          data: sales,
          backgroundColor: "rgba(59, 130, 246, 0.6)",
          borderColor: "#3b82f6",
          borderWidth: 1,
          borderRadius: 4,
          yAxisID: "y"
        },
        {
          label: "Margin %",
          data: margins,
          type: "line",
          borderColor: "#10b981",
          backgroundColor: "#10b981",
          borderWidth: 2,
          pointRadius: 3,
          tension: 0.3,
          yAxisID: "y1"
        }
      ]
    },
    options: {
      responsive: true,
      maintainAspectRatio: false,
      scales: {
        x: { grid: { color: "rgba(51, 65, 85, 0.3)" } },
        y: {
          grid: { color: "rgba(51, 65, 85, 0.3)" },
          ticks: { callback: v => "$" + (v / 1000) + "k" }
        },
        y1: {
          position: "right",
          grid: { drawOnChartArea: false },
          ticks: { callback: v => v + "%" }
        }
      }
    }
  });
}

// 2. Category Performance Chart (Bar / Doughnut)
function renderCategoryChart(categoryData) {
  const ctx = document.getElementById("chart-category").getContext("2d");
  
  const labels = categoryData.map(c => c.category);
  const sales = categoryData.map(c => c.sales);
  const profits = categoryData.map(c => c.profit);

  charts.category = new Chart(ctx, {
    type: "bar",
    data: {
      labels: labels,
      datasets: [
        {
          label: "Total Sales",
          data: sales,
          backgroundColor: "rgba(59, 130, 246, 0.7)",
          borderRadius: 6
        },
        {
          label: "Total Profit",
          data: profits,
          backgroundColor: profits.map(p => p < 0 ? "rgba(239, 68, 68, 0.8)" : "rgba(16, 185, 129, 0.8)"),
          borderRadius: 6
        }
      ]
    },
    options: {
      responsive: true,
      maintainAspectRatio: false,
      scales: {
        x: { grid: { color: "rgba(51, 65, 85, 0.3)" } },
        y: {
          grid: { color: "rgba(51, 65, 85, 0.3)" },
          ticks: { callback: v => "$" + (v / 1000) + "k" }
        }
      }
    }
  });
}

// 3. Sub-Category Profit Spectrum (Horizontal Bar)
function renderSubCategoryChart(subData) {
  const ctx = document.getElementById("chart-subcategory").getContext("2d");
  
  // Sort by profit descending
  const sorted = [...subData].sort((a, b) => b.profit - a.profit);
  const labels = sorted.map(s => s.subcategory);
  const profits = sorted.map(s => s.profit);
  const bgColors = profits.map(p => p < 0 ? "rgba(239, 68, 68, 0.85)" : "rgba(16, 185, 129, 0.75)");

  charts.subcategory = new Chart(ctx, {
    type: "bar",
    data: {
      labels: labels,
      datasets: [
        {
          label: "Net Profit / Loss ($)",
          data: profits,
          backgroundColor: bgColors,
          borderRadius: 4
        }
      ]
    },
    options: {
      indexAxis: "y",
      responsive: true,
      maintainAspectRatio: false,
      scales: {
        x: {
          grid: { color: "rgba(51, 65, 85, 0.3)" },
          ticks: { callback: v => "$" + (v / 1000) + "k" }
        },
        y: { grid: { color: "rgba(51, 65, 85, 0.1)" } }
      }
    }
  });
}

// 4. Regional Performance (West, East, Central, South)
function renderRegionalChart(regionalData) {
  const ctx = document.getElementById("chart-regional").getContext("2d");
  
  const labels = regionalData.map(r => r.region);
  const sales = regionalData.map(r => r.sales);
  const margins = regionalData.map(r => r.margin_pct);

  charts.regional = new Chart(ctx, {
    type: "bar",
    data: {
      labels: labels,
      datasets: [
        {
          label: "Revenue ($)",
          data: sales,
          backgroundColor: "rgba(14, 165, 233, 0.6)",
          borderRadius: 6,
          yAxisID: "y"
        },
        {
          label: "Margin %",
          data: margins,
          type: "line",
          borderColor: "#f59e0b",
          backgroundColor: "#f59e0b",
          borderWidth: 2,
          pointRadius: 4,
          yAxisID: "y1"
        }
      ]
    },
    options: {
      responsive: true,
      maintainAspectRatio: false,
      scales: {
        x: { grid: { color: "rgba(51, 65, 85, 0.3)" } },
        y: {
          grid: { color: "rgba(51, 65, 85, 0.3)" },
          ticks: { callback: v => "$" + (v / 1000) + "k" }
        },
        y1: {
          position: "right",
          grid: { drawOnChartArea: false },
          ticks: { callback: v => v + "%" },
          min: 0,
          max: 20
        }
      }
    }
  });
}

// 5. Discount Sensitivity Diagnostic Chart
function renderDiscountSensitivityChart(discountData) {
  const ctx = document.getElementById("chart-discount").getContext("2d");
  
  const labels = discountData.map(d => d.tier);
  const sales = discountData.map(d => d.sales);
  const margins = discountData.map(d => d.margin_pct);

  charts.discount = new Chart(ctx, {
    type: "bar",
    data: {
      labels: labels,
      datasets: [
        {
          label: "Sales Volume ($)",
          data: sales,
          backgroundColor: "rgba(99, 102, 241, 0.5)",
          borderRadius: 6,
          yAxisID: "y"
        },
        {
          label: "Realized Margin %",
          data: margins,
          type: "line",
          borderColor: margins.map(m => m < 0 ? "#ef4444" : "#10b981"),
          backgroundColor: "#10b981",
          segment: {
            borderColor: ctx => ctx.p1.parsed.y < 0 ? "#ef4444" : "#10b981"
          },
          borderWidth: 3,
          pointRadius: 5,
          yAxisID: "y1"
        }
      ]
    },
    options: {
      responsive: true,
      maintainAspectRatio: false,
      scales: {
        x: { grid: { color: "rgba(51, 65, 85, 0.3)" } },
        y: {
          grid: { color: "rgba(51, 65, 85, 0.3)" },
          ticks: { callback: v => "$" + (v / 1000) + "k" }
        },
        y1: {
          position: "right",
          grid: { color: "rgba(239, 68, 68, 0.2)" },
          ticks: { callback: v => v + "%" }
        }
      }
    }
  });
}

// 6. Sub-Category Diagnostic Table
function renderDiagnosticTable(subData) {
  const tbody = document.getElementById("table-body");
  tbody.innerHTML = "";

  subData.forEach(item => {
    const tr = document.createElement("tr");

    let statusBadge = "";
    if (item.profit < 0) {
      statusBadge = '<span class="status-badge status-critical">CRITICAL LOSS</span>';
    } else if (item.margin_pct < 10) {
      statusBadge = '<span class="status-badge status-warning">LOW MARGIN</span>';
    } else {
      statusBadge = '<span class="status-badge status-healthy">HEALTHY</span>';
    }

    tr.innerHTML = `
      <td><strong>${item.subcategory}</strong></td>
      <td>${item.category}</td>
      <td>${formatCurrency(item.sales)}</td>
      <td class="${item.profit < 0 ? 'text-red' : 'text-green'}">${formatCurrency(item.profit)}</td>
      <td class="${item.margin_pct < 0 ? 'text-red' : (item.margin_pct < 10 ? 'text-amber' : 'text-green')}">${formatPct(item.margin_pct)}</td>
      <td>${formatPct(item.avg_discount_pct)}</td>
      <td>${statusBadge}</td>
    `;
    tbody.appendChild(tr);
  });
}

// Filter Interactive Event Handlers
function setupFilterListeners() {
  const yearSelect = document.getElementById("filter-year");
  const regionSelect = document.getElementById("filter-region");
  const categorySelect = document.getElementById("filter-category");
  const resetBtn = document.getElementById("btn-reset");

  function applyFilter() {
    const selYear = yearSelect.value;
    const selRegion = regionSelect.value;
    const selCat = categorySelect.value;

    let kpis = { ...globalData.kpis };
    let subData = [...globalData.subcategory_performance];
    let catData = [...globalData.category_performance];

    // Filter subcategories by category
    if (selCat !== "ALL") {
      subData = subData.filter(s => s.category === selCat);
      catData = catData.filter(c => c.category === selCat);
    }

    // Adjust KPIs dynamically according to filter
    if (selYear !== "ALL") {
      const yrMatch = globalData.yearly_performance.find(y => y.year === selYear);
      if (yrMatch) {
        kpis.total_sales = yrMatch.sales;
        kpis.total_profit = yrMatch.profit;
        kpis.overall_margin_pct = yrMatch.margin_pct;
        kpis.total_orders = yrMatch.orders;
      }
    } else if (selRegion !== "ALL") {
      const regMatch = globalData.regional_performance.find(r => r.region === selRegion);
      if (regMatch) {
        kpis.total_sales = regMatch.sales;
        kpis.total_profit = regMatch.profit;
        kpis.overall_margin_pct = regMatch.margin_pct;
        kpis.total_orders = regMatch.orders;
      }
    }

    updateKPIs(kpis);
    renderDiagnosticTable(subData);

    // Update charts
    if (charts.subcategory) {
      const sorted = [...subData].sort((a, b) => b.profit - a.profit);
      charts.subcategory.data.labels = sorted.map(s => s.subcategory);
      charts.subcategory.data.datasets[0].data = sorted.map(s => s.profit);
      charts.subcategory.data.datasets[0].backgroundColor = sorted.map(s => s.profit < 0 ? "rgba(239, 68, 68, 0.85)" : "rgba(16, 185, 129, 0.75)");
      charts.subcategory.update();
    }
  }

  yearSelect.addEventListener("change", applyFilter);
  regionSelect.addEventListener("change", applyFilter);
  categorySelect.addEventListener("change", applyFilter);

  resetBtn.addEventListener("click", () => {
    yearSelect.value = "ALL";
    regionSelect.value = "ALL";
    categorySelect.value = "ALL";
    initDashboard(globalData);
  });
}

// Fallback loader if offline or fetch restricted
function initDashboardWithEmbeddedData() {
  // Pre-calculated stats from generated database
  globalData = {
    metadata: { title: "Retail Analytics", dataset_rows: 9994 },
    kpis: {
      total_sales: 5892311.06,
      total_profit: 647592.81,
      overall_margin_pct: 10.99,
      total_orders: 9994,
      avg_discount_pct: 10.25
    },
    yearly_performance: [
      { year: "2021", sales: 1110727.01, profit: 115342.39, margin_pct: 10.38, orders: 1897 },
      { year: "2022", sales: 1295893.51, profit: 153568.18, margin_pct: 11.85, orders: 2218 },
      { year: "2023", sales: 1621581.33, profit: 181253.57, margin_pct: 11.18, orders: 2719 },
      { year: "2024", sales: 1864109.21, profit: 197428.67, margin_pct: 10.59, orders: 3160 }
    ],
    category_performance: [
      { category: "Technology", sales: 3066389.27, profit: 844931.37, margin_pct: 27.55 },
      { category: "Office Supplies", sales: 909703.93, profit: 150988.42, margin_pct: 16.6 },
      { category: "Furniture", sales: 1916217.86, profit: -348326.98, margin_pct: -18.18 }
    ],
    subcategory_performance: [
      { subcategory: "Copiers", category: "Technology", sales: 1807216.5, profit: 645907.03, margin_pct: 35.74, avg_discount_pct: 8.9 },
      { subcategory: "Phones", category: "Technology", sales: 415298.03, profit: 102483.77, margin_pct: 24.68, avg_discount_pct: 8.4 },
      { subcategory: "Accessories", category: "Technology", sales: 213910.84, profit: 59023.72, margin_pct: 27.59, avg_discount_pct: 9.0 },
      { subcategory: "Chairs", category: "Furniture", sales: 478555.04, profit: 43319.0, margin_pct: 9.05, avg_discount_pct: 8.8 },
      { subcategory: "Binders", category: "Office Supplies", sales: 196715.33, profit: 52264.12, margin_pct: 26.57, avg_discount_pct: 9.4 },
      { subcategory: "Appliances", category: "Office Supplies", sales: 283328.23, profit: 42496.75, margin_pct: 15.0, avg_discount_pct: 9.2 },
      { subcategory: "Storage", category: "Office Supplies", sales: 208258.79, profit: 32507.78, margin_pct: 15.61, avg_discount_pct: 9.3 },
      { subcategory: "Machines", category: "Technology", sales: 629963.9, profit: 37516.85, margin_pct: 5.96, avg_discount_pct: 9.7 },
      { subcategory: "Supplies", category: "Office Supplies", sales: 87410.1, profit: -15588.22, margin_pct: -17.83, avg_discount_pct: 15.8 },
      { subcategory: "Bookcases", category: "Furniture", sales: 444136.87, profit: -67267.6, margin_pct: -15.15, avg_discount_pct: 15.0 },
      { subcategory: "Tables", category: "Furniture", sales: 895780.03, profit: -340551.69, margin_pct: -38.02, avg_discount_pct: 15.1 }
    ],
    regional_performance: [
      { region: "South", sales: 1534408.01, profit: 220478.53, orders: 2514, margin_pct: 14.37, avg_discount_pct: 8.3 },
      { region: "East", sales: 1368555.69, profit: 186599.94, orders: 2288, margin_pct: 13.63, avg_discount_pct: 7.8 },
      { region: "West", sales: 1537627.52, profit: 170732.84, orders: 2622, margin_pct: 11.1, avg_discount_pct: 8.2 },
      { region: "Central", sales: 1451719.84, profit: 69781.5, orders: 2570, margin_pct: 4.81, avg_discount_pct: 16.4 }
    ],
    monthly_trend: [
      { month: "Jan", sales: 125000, margin_pct: 11.2 },
      { month: "Feb", sales: 132000, margin_pct: 10.8 },
      { month: "Mar", sales: 148000, margin_pct: 11.5 },
      { month: "Apr", sales: 142000, margin_pct: 10.9 },
      { month: "May", sales: 156000, margin_pct: 11.7 },
      { month: "Jun", sales: 161000, margin_pct: 11.4 },
      { month: "Jul", sales: 168000, margin_pct: 12.1 },
      { month: "Aug", sales: 175000, margin_pct: 11.8 },
      { month: "Sep", sales: 198000, margin_pct: 12.5 },
      { month: "Oct", sales: 205000, margin_pct: 12.2 },
      { month: "Nov", sales: 254000, margin_pct: 13.1 },
      { month: "Dec", sales: 289000, margin_pct: 13.8 }
    ],
    discount_sensitivity: [
      { tier: "0% (Full Price)", sales: 3200000, profit: 620000, margin_pct: 19.38 },
      { tier: "1% - 15% (Low Promo)", sales: 1400000, profit: 180000, margin_pct: 12.86 },
      { tier: "16% - 25% (Moderate)", sales: 750000, profit: 45000, margin_pct: 6.0 },
      { tier: "26% - 40% (Aggressive)", sales: 380000, profit: -85000, margin_pct: -22.37 },
      { tier: "40%+ (Deep Clearance)", sales: 162000, profit: -112000, margin_pct: -69.14 }
    ]
  };
  initDashboard(globalData);
}
