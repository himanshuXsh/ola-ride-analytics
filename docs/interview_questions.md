# Interview Preparation Guide: OLA Ride Analytics & Operations Intelligence

This document provides 25 comprehensive, recruiter-tested interview questions and answers based directly on this project. The answers are structured using clear business reasoning, technical precision, and practical examples suitable for entry-level and junior-to-mid data analyst interviews.

---

## Section 1: Project Origin & Business Problem

### Q1: Why did you create this project?
**Answer**:
I created this project to demonstrate an end-to-end data analytics workflow on real-world ride-hailing transactional data. Ride-hailing platforms like OLA and Uber operate on tight unit margins and sensitive supply-demand balances. I wanted to analyze key operational challenges such as trip completion rates, cancellation root causes, revenue concentration across vehicle tiers, and mutual driver-customer rating dynamics using SQL and Power BI.

### Q2: Can you describe the dataset structure and its key attributes?
**Answer**:
The dataset contains transactional booking records for ride requests in Bengaluru during July 2024. Key attributes include:
- **Identifiers**: `Booking_ID`, `Customer_ID`
- **Temporal**: `Date`, `Time`
- **Operational Status**: `Booking_Status` (e.g. *Success*, *Canceled by Driver*, *Canceled by Customer*, *Driver Not Found*)
- **Fleet Attributes**: `Vehicle_Type` (Auto, Bike, eBike, Mini, Prime Sedan, Prime Plus, Prime SUV)
- **Geographical**: `Pickup_Location`, `Drop_Location`
- **Performance & Durations**: `V_TAT` (Vehicle Turnaround Time / arrival delay), `C_TAT` (Customer boarding wait time)
- **Monetary & Physical**: `Booking_Value` (fare in INR), `Ride_Distance` (km), `Payment_Method`
- **Quality & Feedback**: `Driver_Ratings`, `Customer_Rating` (1.0 to 5.0 scale)

---

## Section 2: Data Cleaning & SQL Engineering

### Q3: What data quality issues did you encounter, and how did you resolve them?
**Answer**:
I uncovered several data quality anomalies in the raw CSV export:
1. **String `'null'` Literals**: Missing values were exported as literal text strings `'null'` or empty strings rather than true database `NULL`s. I converted these using `CASE` statements and `NULLIF()`.
2. **Corrupted Spreadsheet Artifacts**: The vehicle images column contained `#NAME?` errors from Excel formula corruption. I handled this by sanitizing and excluding the column from production tables.
3. **Date and Time Formatting**: Raw timestamps included mixed date-time strings. I parsed them into separate standard MySQL `DATE` and `TIME` data types using `STR_TO_DATE()` and `CAST()`.
4. **Out-of-Bounds Ratings**: Handled non-completed trips where ratings were legitimately `NULL` and ensured completed trip ratings stayed strictly within `[1.00, 5.00]`.

### Q4: Why did you use a two-tier table architecture (`raw_bookings` and `ola_bookings`)?
**Answer**:
Using a two-tier architecture separates **data ingestion** from **data consumption**:
- `raw_bookings` acts as a staging table with permissive text datatypes (`VARCHAR`), allowing the raw CSV to load without aborting on type mismatches.
- `ola_bookings` is the clean, production table with strict data types (`INT`, `DECIMAL`, `DATE`), primary keys, and indexes. This ensures analytics and Power BI dashboards query only validated, sanitized data.

### Q5: What is the difference between a SQL View and a physical Table, and why did you create 18 views?
**Answer**:
A **table** stores physical data on disk, whereas a **view** is a saved, virtual SQL query that runs on-demand against underlying tables without duplicating storage.
I created 18 views (e.g., `vw_successful_bookings`, `vw_vehicle_performance_metrics`) to encapsulate complex business logic, reusable filters, and aggregations. This provides a clean semantic layer for Power BI and prevents analysts from having to rewrite long SQL queries repeatedly.

### Q6: How did you use `GROUP BY` and conditional aggregation in your analysis?
**Answer**:
`GROUP BY` aggregates individual trip records into summary categories (e.g., grouping by `vehicle_type` to calculate total rides).
I combined `GROUP BY` with conditional `CASE` statements to calculate multiple segmented metrics in a single pass. For example:
```sql
SELECT 
    vehicle_type,
    COUNT(*) AS total_bookings,
    SUM(CASE WHEN booking_status = 'Success' THEN 1 ELSE 0 END) AS successful_bookings,
    SUM(CASE WHEN booking_status = 'Canceled by Driver' THEN 1 ELSE 0 END) AS driver_cancels
FROM ola_bookings
GROUP BY vehicle_type;
```
This is much more efficient than writing multiple separate queries with `WHERE` clauses.

### Q7: What is a Common Table Expression (CTE), and where did you use it?
**Answer**:
A CTE (defined using the `WITH` keyword) creates a temporary, named result set that exists only during the execution of a query. It makes complex SQL queries much more readable and modular than nested subqueries.
I used CTEs in `06_advanced_analysis.sql` to compute daily revenue aggregates first, and then applied window functions on top of that CTE to calculate Day-Over-Day growth.

### Q8: What are Window Functions, and how do `RANK()`, `DENSE_RANK()`, and `ROW_NUMBER()` differ?
**Answer**:
Window functions perform calculations across a set of table rows related to the current row without collapsing the rows into a single summary output like `GROUP BY` does.
The key differences:
- `ROW_NUMBER()`: Assigns a unique sequential integer to each row (e.g., 1, 2, 3, 4) regardless of ties. Used for de-duplication.
- `RANK()`: Assigns rank values but skips numbers on ties (e.g., 1, 2, 2, 4).
- `DENSE_RANK()`: Assigns rank values on ties without skipping numbers (e.g., 1, 2, 2, 3). Used to identify top customer spenders.

### Q9: How did you use the `LAG()` function in your analysis?
**Answer**:
`LAG()` allows a query to access data from a preceding row at a specified physical offset without performing a self-join.
I used `LAG(daily_revenue, 1) OVER (ORDER BY ride_date)` to retrieve the previous day's revenue and calculate the Day-over-Day (DoD) growth percentage:
```sql
ROUND((daily_revenue - LAG(daily_revenue, 1) OVER (ORDER BY ride_date)) * 100.0 / 
      NULLIF(LAG(daily_revenue, 1) OVER (ORDER BY ride_date), 0), 2) AS dod_growth_pct
```

---

## Section 3: Business Metrics & Key Insights

### Q10: How do you calculate Completion Rate and Cancellation Rate, and what do they indicate?
**Answer**:
- **Completion Rate**: `Successful Bookings / Total Bookings`. It measures platform fulfillment efficiency and reliability.
- **Cancellation Rate**: `Cancelled Bookings / Total Bookings`. It measures friction and unfulfilled demand.
Together, they provide the primary health funnel for the platform. If cancellation rates rise above 20-25%, it signals severe driver availability issues or passenger wait-time dissatisfaction.

### Q11: How is Successful Revenue calculated, and why do we exclude cancelled rides?
**Answer**:
Successful Revenue is the sum of `booking_value` strictly where `booking_status = 'Success'`.
Cancelled rides must be excluded because no transportation service was delivered, and no gross fare was settled. Including cancelled ride fare quotes would artificially inflate reported revenue.

### Q12: What is the "Rating Gap" metric, and what does it tell management?
**Answer**:
The **Rating Gap** is the difference between average driver rating and average customer rating:
`Rating Gap = Average Driver Rating - Average Customer Rating`.
A significant negative gap (riders rating drivers much lower than drivers rate riders) signals customer dissatisfaction with vehicle hygiene, driver behavior, or route navigation. A positive gap suggests passengers are well-behaved and appreciative of drivers.

### Q13: What were the most common reasons for driver and customer cancellations?
**Answer**:
- **Driver Cancellations**: Dominated by *Personal & Car-related issues* and *Customer-related issues* (e.g. incorrect pickup address or customer not picking up phone calls).
- **Customer Cancellations**: Dominated by *Driver not moving towards pickup location* and *Excessive wait times*. This proved a strong correlation between high Vehicle Turnaround Time (`V_TAT`) and customer cancellation spikes.

---

## Section 4: Power BI Architecture & Modeling

### Q14: What is the difference between a Power BI Report and a Power BI Dashboard?
**Answer**:
- **Report**: Multi-page, highly interactive analytical document built on a single dataset. Offers slicers, filters, bookmarks, drill-throughs, and detailed cross-filtering.
- **Dashboard**: A single-page executive canvas (available in Power BI Service) that pins high-level tiles and KPIs from multiple underlying reports to provide a quick high-level overview.

### Q15: Why did you use a Star Schema instead of keeping one flat table in Power BI?
**Answer**:
While flat denormalized tables work for simple exercises, a **Star Schema** with a central fact table (`FactRides`) and dimension tables (`DimDate`, `DimVehicle`, `DimCustomer`, `DimPaymentMethod`):
1. Reduces memory usage via VertiPaq columnar compression.
2. Eliminates ambiguous relationship loops and bidirectional filtering issues.
3. Greatly simplifies DAX calculations, especially Time Intelligence functions.

### Q16: Why should you always use `DIVIDE()` instead of direct division `/` in DAX?
**Answer**:
Direct division (`A / B`) returns `NaN` or crashes with a divide-by-zero error if the denominator is `0` or blank.
The `DIVIDE(A, B, 0)` function handles zero or empty denominators safely by returning an alternate result (such as `0` or blank), keeping visual cards and charts clean and error-free.

### Q17: Can you explain the difference between `CALCULATE()` and `SUM()` in DAX?
**Answer**:
`SUM()` is a simple aggregation function that adds numeric values in a column within the current filter context.
`CALCULATE()` is the most powerful function in DAX because it allows you to **modify or override the existing filter context**. For instance, to calculate revenue only for completed rides:
```dax
Successful Revenue = CALCULATE(SUM(FactRides[booking_value]), FactRides[booking_status] = "Success")
```
Here, `CALCULATE` modifies the context to evaluate only rows where `booking_status` equals `"Success"`.

### Q18: What is the difference between DirectQuery and Import Mode in Power BI?
**Answer**:
- **Import Mode**: Power BI loads and compresses the dataset into memory (RAM). Delivers blazing fast report interactions and supports all DAX functions, but requires scheduled data refreshes.
- **DirectQuery**: Power BI does not store data in memory; every user click sends live SQL queries to the underlying database. Useful for massive datasets (terabytes) or real-time requirements, but query latency can slow down dashboards.
In this project, I recommended **Import Mode** for responsive visual rendering and full time-intelligence support.

---

## Section 5: Dashboard Design & UX Decisions

### Q19: What design principles guided your dashboard layout?
**Answer**:
I followed five core principles:
1. **Z-Pattern Layout**: Executive summary KPIs are anchored at the top, high-level trends in the middle, and detailed operational tables at the bottom.
2. **Strict Visual Budget**: Limited each canvas to **6 to 8 visuals** to avoid cognitive overload.
3. **Semantic Color Palette**: Green for success, red for cancellations, orange for incomplete trips, and blue for revenue.
4. **Dual Encoding**: Never relying on color alone; always pairing color with labels, icons, and formatted tooltips.
5. **Interactive Exploration**: Adding a "Reset Filters" bookmark button, drill-through pages for fleet deep-dives, and custom tooltip cards.

### Q20: How did you implement the "Reset Filters" button in Power BI?
**Answer**:
1. Reset all slicers and page filters to default (all selected).
2. Captured this clean state as a **Bookmark** named `"Reset Filters"` in the Bookmarks Pane (configuring it to affect Data/Slicers).
3. Inserted a button on the canvas, enabled **Action**, set the type to **Bookmark**, and selected `"Reset Filters"`. When clicked, it restores the default view instantly.

---

## Section 6: Limitations, Deployment & Future Improvements

### Q21: What are the main limitations of this dataset?
**Answer**:
1. **Time Horizon**: Covers only a single month (July 2024), which prevents multi-year seasonal analysis (e.g. Diwali festival spikes or monsoon vs summer comparisons).
2. **Geographical Scope**: Limited to Bengaluru pickup and drop locations.
3. **Driver Anonymity**: Lacks explicit driver IDs, preventing driver-level tenure or churn analysis.
4. **Surge Pricing Data**: Base fare and surge multipliers are combined into a single `booking_value`, so we cannot separate surge pricing elasticities from regular distance fares.

### Q22: How would you deploy this project in an enterprise production environment?
**Answer**:
In an enterprise environment:
1. **Automated ETL**: Use Apache Airflow or Azure Data Factory to ingest incremental ride logs daily from Kafka/S3 into an analytical data warehouse (Snowflake, BigQuery, or Amazon Redshift).
2. **CI/CD & Version Control**: Manage SQL transformation models with **dbt** (data build tool), utilizing Git version control and automated unit testing.
3. **Power BI Deployment Pipelines**: Publish reports to Power BI Service via Development, Test, and Production workspaces with scheduled gateway refreshes and Row-Level Security (RLS) configured by region.

### Q23: How could machine learning be integrated into this analytics pipeline?
**Answer**:
1. **Predictive Ride Cancellation Model**: Train a classification model (XGBoost / LightGBM) on `v_tat`, pickup hour, vehicle type, and historical cancellation rates to predict cancellation risk at the moment of booking dispatch.
2. **Dynamic ETA / TAT Prediction**: Train regression models to improve vehicle arrival time estimates.
3. **Customer Churn & CLV Prediction**: Identify riders showing declining booking frequency and trigger personalized retention offers.

### Q24: How would you explain this project in a 2-minute elevator pitch to a hiring manager?
**Answer**:
"In this project, I built an end-to-end analytics and operations intelligence solution for an OLA ride-booking dataset with over 100,000 transactions.
I started by architecting a two-tier MySQL database, writing automated SQL scripts to audit 12 data quality checkpoints and clean raw formatting anomalies like string nulls and corrupted artifacts.
I built 18 production analytical views and used advanced window functions like `LAG()` and `DENSE_RANK()` to analyze Day-over-Day revenue growth, peak booking hours, and turnaround time impact on cancellations.
Finally, I designed a 4-page Power BI executive suite following a star schema and WCAG accessibility standards. The dashboard allows leadership to evaluate completion rates, revenue contribution by vehicle tier and payment method, operational bottlenecks, and mutual driver-customer rating dynamics.
This project demonstrated my ability to take messy transactional data, establish clean data pipelines, and produce business intelligence that directly guides operations."

### Q25: What is your favorite SQL query or feature you built in this project and why?
**Answer**:
My favorite query is the **TAT Sensitivity and Cancellation Probability analysis** in `06_advanced_analysis.sql`.
I bucketed vehicle turnaround times (`V_TAT`) into arrival intervals (`0-2m`, `2-5m`, `5-10m`, `10+m`) and calculated conditional cancellation rates for each bucket. It clearly showed how delays in driver arrival exponentially drive customer cancellations. It's a great example of using SQL not just to report historical numbers, but to deliver actionable operational insight.
