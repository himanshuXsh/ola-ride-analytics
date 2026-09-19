# SQL Analytics Engine & Data Pipeline

This directory contains the production-grade MySQL scripts for the **OLA Ride Analytics and Operations Intelligence** project. The pipeline ingests raw transactional data, runs 12 automated integrity checks, cleans and types the dataset, creates 18 core analytical views, and performs advanced window-function analytics.

---

## Script Execution Pipeline

Execute the scripts sequentially in the following order:

| Step | Script | Purpose | Key Objects Created / Touched |
|:---:|:---|:---|:---|
| **01** | `01_create_database.sql` | Initialize schema, character sets, and session settings | Database: `ola_ride_analytics` |
| **02** | `02_create_tables.sql` | Define staging and production relational tables | Tables: `raw_bookings`, `ola_bookings` |
| **03** | `03_data_quality_checks.sql` | Run 12 data integrity and validation audits | Audit reports on `raw_bookings` |
| **04** | `04_cleaning_logic.sql` | ETL: De-duplicate, nullify, type-cast, and load | Population of `ola_bookings` |
| **05** | `05_analytical_views.sql` | Core business reporting and KPI views | 18 production views (`vw_*`) |
| **06** | `06_advanced_analysis.sql` | Window functions, DoD trends, deciles, and heatmaps | Analytical query suite |

---

## Prerequisites

- **MySQL Server**: Version 8.0 or later (required for Window Functions like `DENSE_RANK()`, `LAG()`, `NTILE()`).
- **Client**: MySQL Command Line Interface (CLI) or MySQL Workbench.
- **Local Data**: Place the raw dataset file `Bookings.csv` in the local `data/` directory.

---

## How to Run the Scripts

### Option A: Using MySQL Command Line Interface (Recommended)

1. Open your terminal or PowerShell and navigate to the project directory:
   ```bash
   cd ola-ride-analytics/sql
   ```

2. Run the scripts sequentially:
   ```bash
   # Step 1: Create Database
   mysql -u root -p < 01_create_database.sql

   # Step 2: Create Tables
   mysql -u root -p ola_ride_analytics < 02_create_tables.sql

   # Ingest raw CSV data into raw_bookings (adjust path if needed)
   # Or use MySQL Workbench Table Data Import Wizard
   ```

3. To import the CSV via MySQL CLI:
   ```sql
   USE ola_ride_analytics;
   LOAD DATA LOCAL INFILE '../data/Bookings.csv'
   INTO TABLE raw_bookings
   FIELDS TERMINATED BY ','
   ENCLOSED BY '"'
   LINES TERMINATED BY '\n'
   IGNORE 1 ROWS;
   ```

4. Continue running the cleaning and analytical scripts:
   ```bash
   # Step 3: Run Data Integrity Checks
   mysql -u root -p ola_ride_analytics < 03_data_quality_checks.sql

   # Step 4: Execute Cleaning & Population Pipeline
   mysql -u root -p ola_ride_analytics < 04_cleaning_logic.sql

   # Step 5: Build Analytical Views
   mysql -u root -p ola_ride_analytics < 05_analytical_views.sql

   # Step 6: Execute Advanced Queries
   mysql -u root -p ola_ride_analytics < 06_advanced_analysis.sql
   ```

### Option B: Using MySQL Workbench

1. Open **MySQL Workbench** and connect to your local instance.
2. Open `01_create_database.sql` and click the **Execute (Lightning)** button.
3. Open `02_create_tables.sql` and execute.
4. Right-click on the `raw_bookings` table in the schema navigator and choose **Table Data Import Wizard**. Select `data/Bookings.csv` and complete the import.
5. Open and execute `03_data_quality_checks.sql` to inspect audit logs.
6. Open and execute `04_cleaning_logic.sql` to sanitize and populate `ola_bookings`.
7. Open and execute `05_analytical_views.sql` to generate all 18 views.
8. Run `06_advanced_analysis.sql` to generate advanced analytical insights.

---

## Detailed Script Descriptions

### `01_create_database.sql`
Establishes the database with `utf8mb4` character set and `utf8mb4_unicode_ci` collation, ensuring compatibility with special characters, text emojis, and multilingual text. Sets session time zone to India Standard Time (`+05:30`).

### `02_create_tables.sql`
Defines a two-tier data architecture:
- **`raw_bookings`**: Ingestion staging table with permissive text fields. Prevents import failure due to type mismatches, empty values, or raw text representations like `'null'`.
- **`ola_bookings`**: Production analytics table. Strictly typed with `DATE`, `TIME`, `DECIMAL(10,2)` for financial metrics, `INT` for durations, and secondary indexes on high-cardinality search columns (`ride_date`, `booking_status`, `vehicle_type`, `customer_id`, `payment_method`).

### `03_data_quality_checks.sql`
Runs 12 validation rules:
- Duplicate checking (primary key and full-row).
- Missing identifier audits (`customer_id`, `vehicle_type`, `booking_status`).
- Payment method validation for completed rides.
- Rating domain checks (ensuring ratings stay strictly within `[1.00, 5.00]`).
- Value boundary checks (ensuring non-negative revenue and ride distance).
- Cancellation justification completeness.
- Concludes with a unified **Data Quality Audit Report** query.

### `04_cleaning_logic.sql`
Implements an enterprise-grade transformation pipeline:
- De-duplicates rows via `ROW_NUMBER() OVER (PARTITION BY booking_id ORDER BY ride_date DESC)`.
- Converts text `'null'`, empty strings, and whitespace to native SQL `NULL`.
- Converts date formats (`YYYY-MM-DD HH:MM:SS` and `YYYY-MM-DD`) using `STR_TO_DATE`.
- Converts time strings to standard MySQL `TIME`.
- Discards corrupted spreadsheet artifacts like `#NAME?` in the vehicle images column.

### `05_analytical_views.sql`
Constructs 18 production database views:
1. `vw_successful_bookings`: All completed rides.
2. `vw_avg_ride_distance_by_vehicle`: Distance profiles by vehicle category.
3. `vw_bookings_by_status`: Volume and percentage split across all ride statuses.
4. `vw_top_5_customers_by_rides`: Top riders by ride count.
5. `vw_top_customers_by_revenue`: Top riders by total spend (INR).
6. `vw_driver_cancellations_by_reason`: Driver cancellation root causes.
7. `vw_customer_cancellations_summary`: Passenger cancellation reasons.
8. `vw_max_min_driver_ratings`: Driver rating extremes across vehicle types (including Prime Sedan).
9. `vw_avg_customer_rating_by_vehicle`: Passenger ratings across vehicle categories.
10. `vw_successful_revenue_summary`: Aggregate realized revenue, average booking value, and revenue per km.
11. `vw_revenue_by_payment_method`: Channel revenue share (UPI, Cash, Credit Card, Debit Card).
12. `vw_revenue_by_vehicle_type`: Fleet revenue contribution.
13. `vw_cancellation_reason_analysis`: Unified driver and passenger cancellation taxonomy.
14. `vw_incomplete_rides_analysis`: Mid-trip abort reasons.
15. `vw_vehicle_performance_metrics`: Consolidated 360-degree scorecard for each vehicle tier.
16. `vw_customer_booking_summary`: Customer frequency segmentation (One-Time, Occasional, Regular, Power User).
17. `vw_rating_comparison`: Driver vs customer rating parity and sentiment bias.
18. `vw_operational_exceptions`: Outlier trips (TAT > 10 mins, zero-fare completions, incomplete rides).

### `06_advanced_analysis.sql`
Advanced analytical routines:
- **Day-Over-Day (DoD) Growth**: Utilizes `LAG()` to calculate percentage revenue and volume shifts.
- **Hourly Heatmap**: Aggregates booking volume, cancellation rate, and average fare by hour of day (`0-23`).
- **Pareto Spend Deciles**: Partitions users into 10 spending tiers using `NTILE(10)` to assess GMV concentration.
- **Route Corridors**: Ranks top origin-destination pairs using `DENSE_RANK()`.
- **TAT Sensitivity**: Evaluates cancellation probability against turnaround times (`V_TAT`, `C_TAT`).
