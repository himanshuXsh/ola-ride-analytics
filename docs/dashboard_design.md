# Power BI Dashboard Design System & UI/UX Standards

This document establishes the UI/UX architecture, visual hierarchy, semantic color design system, accessibility guidelines, and interaction rules for the **OLA Ride Analytics and Operations Intelligence** reporting suite.

---

## 1. Visual Hierarchy & Page Layout Architecture

The report adopts a standardized **16:9 widescreen canvas** (1280 × 720 px or 1920 × 1080 px) utilizing a **Z-Pattern visual reading hierarchy**:

```
+---------------------------------------------------------------------------------+
|  HEADER BANNER: Page Title | Active Filters Context | Refresh Timestamp | Logo  |
+---------------------------------------------------------------------------------+
|  TOP ROW: Executive KPI Summary Ribbon (5-6 Metric Cards with % comparisons)    |
+------------------------------------+--------------------------------------------+
|  MID-LEFT: Primary Macro Trend     |  MID-RIGHT: Categorical Distribution       |
|  (Line / Area Time-Series Chart)   |  (Horizontal Bar / Treemap Breakdown)      |
+------------------------------------+--------------------------------------------+
|  BOTTOM-LEFT: Operational Detail   |  BOTTOM-RIGHT: Deep-Dive Tabular Matrix    |
|  (Root-Cause Pareto Chart)         |  (Conditional Formatting & Action Items)  |
+------------------------------------+--------------------------------------------+
```

### Layout Best Practices
- **Strict Visual Limit**: Maintain between **6 and 8 meaningful visuals** per canvas. Clutter degrades cognitive processing and slows down report rendering.
- **Whitespace Discipline**: Ensure a minimum 12px margin between cards and charts to eliminate visual fatigue.
- **Top Anchoring**: High-level aggregations (KPI cards) must be strictly anchored to the top 15% of the screen.

---

## 2. Semantic Color System

To maintain clarity and prevent cognitive confusion, color is assigned semantically across all pages:

| Role | Hex Code | Visual Sample | Usage Guideline |
|:---|:---:|:---:|:---|
| **Success / Completed** | `#2ECC71` | Forest Emerald | Successful rides, positive growth trends, completed KPIs |
| **Cancellation / Danger** | `#E74C3C` | Crimson Red | Driver/customer cancellations, missed targets |
| **Incomplete / Warning** | `#E67E22` | Amber Orange | Incomplete trips, severe TAT delays (>10 min) |
| **Revenue / Financial** | `#2980B9` | Marine Blue | Gross booking value, average ticket sizes, payment channels |
| **Primary Neutral / Dark**| `#2C3E50` | Slate Charcoal | Chart titles, axis labels, dark theme containers |
| **Secondary Neutral / Muted**| `#7F8C8D` | Cool Gray | Benchmark reference lines, grid lines, subtotals |
| **Canvas Background** | `#F8F9FA` | Soft Off-White | Canvas background color reducing glare |

> [!IMPORTANT]
> **Dual Encoding Rule**: Never rely solely on color to communicate state. Always pair color with text indicators, trend symbols (`▲`, `▼`), or explicit data labels so colorblind users can interpret data effortlessly.

---

## 3. Recommended Visual Selection Matrix

| Business Objective | Recommended Chart Type | Visual to Avoid | Design Rationale |
|:---|:---|:---|:---|
| **Demand Over Time** | Line Chart with Data Markers | 3D Area Chart | Displays clean trajectory without perspective distortion. |
| **Fleet Comparison** | Horizontal Bar Chart | Pie Chart with >3 slices | Allows instant horizontal label reading without neck craning. |
| **Status Breakdown** | Donut Chart (Max 4 slices) | Multi-layer Sunburst | Clear proportion of whole with total in center. |
| **Revenue by Channel**| Clustered Column Chart | Radar / Spider Chart | Distinct column heights enable intuitive comparisons. |
| **Outlier Exception Review**| Matrix with Data Bars | Plain text unformatted table| Visual data bars highlight variance instantly. |
| **Rating Parity** | Grouped Clustered Column | Dual-axis Gauge | Side-by-side comparison on identical Y-axis scale (1-5). |

---

## 4. Number Formatting Standards

Consistent typography and number masks reinforce professional quality:

- **Monetary Values (INR)**: `₹#,##0` for thousands/lakhs (e.g., `₹4,25,800`) or `₹#,##0.00` for averages (e.g., `₹384.50`).
- **Percentages**: `0.0%` (e.g., `72.4%`). Always display 1 decimal place to capture small but significant shifts.
- **Durations / Turnaround Time**: Displayed as whole seconds or formatted as minutes (`m:ss`).
- **Ratings**: Fixed 2 decimal precision (e.g., `4.25 ★`).
- **Counts / Volume**: Comma-separated integer (`#,##0`).

---

## 5. Interaction Patterns: Slicers, Bookmarks & Drill-Through

### Slicers
- Positioned in a collapsible left pane or top header ribbon.
- **Date Slicer**: Relative date slider or range calendar with standard presets (Last 7 Days, Month-to-Date).
- **Categorical Slicers**: Dropdown mode with search bar enabled for high-cardinality attributes (`pickup_location`).
- **Default Selections**: Provide an explicit **"Reset Filters"** bookmark button to prevent users from getting lost in nested cross-filters.

### Bookmarks
1. **Reset Filters**: Restores all slicers to `All` without reloading data.
2. **View Toggles**: Switch between **Volume View** (Count of Rides) and **Revenue View** (GMV in INR) without duplicating canvas pages.

### Drill-Through Navigation
- **Vehicle Deep-Dive**: Users right-click any vehicle bar (e.g. `Auto`) and select **Drill-through > Vehicle Analysis** to view trip distance distributions, average speeds, and cancellation trends specific to that fleet.
- **Customer Profile**: Drill-through on customer ID displays lifetime ride history and preferred transit corridors.

### Visual Tooltip Pages
- Configure lightweight (320 × 200 px) tooltip pages.
- Hovering over a vehicle category in a bar chart instantly exposes a mini scorecard showing:
  - Top cancellation reason
  - Average trip distance
  - Revenue per km

---

## 6. Accessibility & Inclusivity Standards (WCAG 2.1 AA)

1. **Contrast Ratio**: Text against background exceeds the standard **4.5:1** contrast ratio.
2. **Screen Reader Support**: Meaningful alt-text populated in **Format > General > Alt Text** for every visual element.
3. **Tab Navigation Order**: Configured in the Selection Pane to ensure logical keyboard navigation across cards and slicers.
4. **Font Selection**: Universal, accessible sans-serif typography (`Segoe UI`, `DIN`, or `Arial`).

---

## 7. Ten Common Power BI Anti-Patterns & How This Project Solves Them

| Anti-Pattern | Operational Risk | Our Architectural Solution |
|:---|:---|:---|
| **1. 3D Charts & Gradients** | Distorts scale and misleads perception | Clean, flat 2D visuals with solid fills |
| **2. Unformatted Raw Numbers** | Hard for executives to scan quickly | Rigorous custom formatting (`₹`, `%`, commas) |
| **3. Slicer Clutter** | Takes up half the screen space | Consolidated dropdown slicers with search |
| **4. Inconsistent Palette** | Same color represents different entities | Strict semantic color dictionary (Green=Success) |
| **5. Non-Existent Error Handling**| Displays `#ERROR` or blank on empty filters | Safe DAX `DIVIDE(..., 0)` and `COALESCE` |
| **6. Visual Overcrowding (>12 visuals)**| Cognitive overload and sluggish rendering | Strict 6-8 visual budget per canvas |
| **7. Ambiguous Chart Titles** | Users don't understand the metric | Explicit descriptive titles (e.g. "Revenue by Payment Channel (INR)") |
| **8. Missing Date Dimension** | Auto-Date/Time bloats model file size | Dedicated custom `DimDate` table in DAX |
| **9. Bidirectional Filtering Everywhere**| Ambiguous filter paths and performance hit | 1-to-many single-direction filtering in Star Schema |
| **10. Neglecting Mobile View** | Dashboard unreadable on mobile/tablet | Optimized responsive card layouts |
