# Metric Definitions & KPI Data Dictionary

This document provides mathematical formulations, required database columns, DAX expressions, SQL logic, business significance, and operational caveats for all key performance indicators (KPIs) in the **OLA Ride Analytics and Operations Intelligence** project.

---

## Metric Summary Matrix

| Metric Name | Business Category | Target Direction | Primary Granularity |
|:---|:---|:---:|:---|
| **Total Bookings** | Demand & Volume | Contextual / Up | Daily / Vehicle / Corridor |
| **Successful Bookings** | Fulfillment | Maximise (▲) | Platform / Vehicle |
| **Completion Rate** | Service Reliability | Maximise (▲ > 75%) | Platform / Fleet Tier |
| **Cancellation Rate** | Operational Friction | Minimise (▼ < 25%) | Party (Driver vs Rider) |
| **Successful Revenue (GMV)** | Financial | Maximise (▲) | Daily / Channel / Fleet |
| **Average Booking Value (ABV)**| Revenue Quality | Maximise (▲) | Vehicle Type / Corridor |
| **Revenue per Kilometre** | Unit Economics | Optimal Efficiency | Vehicle Tier |
| **Rating Gap** | Platform Health | Neutral Parity (~0.0) | Fleet Category |

---

## Detailed KPI Definitions

### 1. Total Bookings
- **Business Meaning**: The aggregate count of ride requests submitted by users across the application, representing gross market demand regardless of eventual fulfillment.
- **Formula**:
  $$\text{Total Bookings} = \sum 1 = N$$
- **Required Columns**: `booking_id`
- **SQL Implementation**:
  ```sql
  SELECT COUNT(booking_id) AS total_bookings FROM ola_bookings;
  ```
- **DAX Implementation**:
  ```dax
  Total Bookings = COUNTROWS(FactRides)
  ```
- **Operational Nuances & Limitations**: Includes immediate rider cancellations, unfulfilled searches (`Driver Not Found`), and network drops. Does not reflect app visits where no request was dispatched.

---

### 2. Successful Bookings
- **Business Meaning**: Ride requests that concluded with the passenger safely arriving at their destination and payment settled.
- **Formula**:
  $$\text{Successful Bookings} = \sum_{\text{status} = \text{'Success'}} 1$$
- **Required Columns**: `booking_id`, `booking_status`
- **SQL Implementation**:
  ```sql
  SELECT COUNT(booking_id) AS successful_bookings 
  FROM ola_bookings 
  WHERE booking_status = 'Success';
  ```
- **DAX Implementation**:
  ```dax
  Successful Bookings = 
  CALCULATE(COUNTROWS(FactRides), FactRides[booking_status] = "Success")
  ```
- **Operational Nuances & Limitations**: Does not distinguish between partially completed rides that were marked successful in billing vs seamless journeys unless cross-referenced with `incomplete_rides`.

---

### 3. Completion Rate
- **Business Meaning**: The percentage of generated ride demand that converts into successful fulfilled trips. The benchmark metric for platform reliability.
- **Formula**:
  $$\text{Completion Rate} = \left( \frac{\text{Successful Bookings}}{\text{Total Bookings}} \right) \times 100$$
- **Required Columns**: `booking_id`, `booking_status`
- **SQL Implementation**:
  ```sql
  SELECT 
      ROUND(
          SUM(CASE WHEN booking_status = 'Success' THEN 1 ELSE 0 END) * 100.0 / 
          NULLIF(COUNT(booking_id), 0), 
          2
      ) AS completion_rate_pct
  FROM ola_bookings;
  ```
- **DAX Implementation**:
  ```dax
  Completion Rate = 
  DIVIDE([Successful Bookings], [Total Bookings], 0)
  ```
- **Operational Nuances & Limitations**: A drop in completion rate may stem from external factors (heavy rain, severe gridlock) or supply-demand mismatch (peak hour driver deficits) rather than core platform failure.

---

### 4. Cancellation Rate
- **Business Meaning**: The proportion of initiated bookings aborted prior to trip completion by either the passenger, driver, or dispatch system (`Driver Not Found`).
- **Formula**:
  $$\text{Cancellation Rate} = \left( \frac{\text{Total Bookings} - \text{Successful Bookings}}{\text{Total Bookings}} \right) \times 100$$
- **Required Columns**: `booking_id`, `booking_status`
- **SQL Implementation**:
  ```sql
  SELECT 
      ROUND(
          SUM(CASE WHEN booking_status <> 'Success' THEN 1 ELSE 0 END) * 100.0 / 
          NULLIF(COUNT(booking_id), 0), 
          2
      ) AS cancellation_rate_pct
  FROM ola_bookings;
  ```
- **DAX Implementation**:
  ```dax
  Cancellation Rate = 
  DIVIDE([Cancelled Bookings], [Total Bookings], 0)
  ```
- **Operational Nuances & Limitations**: Must be decomposed into Customer Cancellations, Driver Cancellations, and System Drops (`Driver Not Found`) to diagnose specific operational accountability.

---

### 5. Successful Revenue (Gross Merchandise Value)
- **Business Meaning**: Aggregate financial value of fares collected from completed passenger journeys.
- **Formula**:
  $$\text{Successful Revenue} = \sum_{\text{status} = \text{'Success'}} \text{booking\_value}$$
- **Required Columns**: `booking_value`, `booking_status`
- **SQL Implementation**:
  ```sql
  SELECT ROUND(SUM(booking_value), 2) AS successful_revenue_inr
  FROM ola_bookings
  WHERE booking_status = 'Success';
  ```
- **DAX Implementation**:
  ```dax
  Successful Revenue = 
  CALCULATE(SUM(FactRides[booking_value]), FactRides[booking_status] = "Success")
  ```
- **Operational Nuances & Limitations**: Represents gross passenger fare. It is not net platform take-rate (commission) as driver payouts, fuel incentives, and tax deductions are not segregated in the dataset.

---

### 6. Average Booking Value (ABV)
- **Business Meaning**: The mean gross monetary value generated per completed ride.
- **Formula**:
  $$\text{ABV} = \frac{\text{Successful Revenue}}{\text{Successful Bookings}}$$
- **Required Columns**: `booking_value`, `booking_status`
- **SQL Implementation**:
  ```sql
  SELECT ROUND(AVG(booking_value), 2) AS avg_booking_value_inr
  FROM ola_bookings
  WHERE booking_status = 'Success';
  ```
- **DAX Implementation**:
  ```dax
  Average Booking Value = 
  DIVIDE([Successful Revenue], [Successful Bookings], 0)
  ```
- **Operational Nuances & Limitations**: Heavily skewed by fleet category mix (e.g. higher proportion of long-distance Prime Sedan / SUV rides elevates ABV even if trip volume is flat).

---

### 7. Revenue per Kilometre
- **Business Meaning**: The unit economic yield earned per kilometre of successful transport delivered.
- **Formula**:
  $$\text{Revenue per KM} = \frac{\sum_{\text{status} = \text{'Success'}} \text{booking\_value}}{\sum_{\text{status} = \text{'Success'}} \text{ride\_distance}}$$
- **Required Columns**: `booking_value`, `ride_distance`, `booking_status`
- **SQL Implementation**:
  ```sql
  SELECT 
      ROUND(
          SUM(booking_value) / NULLIF(SUM(ride_distance), 0), 
          2
      ) AS revenue_per_km_inr
  FROM ola_bookings
  WHERE booking_status = 'Success' AND ride_distance > 0;
  ```
- **DAX Implementation**:
  ```dax
  Revenue per KM = 
  DIVIDE([Successful Revenue], [Total Ride Distance], 0)
  ```
- **Operational Nuances & Limitations**: Base fares and minimum distance clauses cause ultra-short trips (<2 km) to exhibit artificially high revenue per kilometre.

---

### 8. Rating Gap
- **Business Meaning**: The arithmetic spread between the average score awarded by drivers to passengers versus the score awarded by passengers to drivers.
- **Formula**:
  $$\text{Rating Gap} = \overline{\text{Driver Rating}} - \overline{\text{Customer Rating}}$$
- **Required Columns**: `driver_ratings`, `customer_rating`, `booking_status`
- **SQL Implementation**:
  ```sql
  SELECT 
      ROUND(AVG(driver_ratings) - AVG(customer_rating), 2) AS rating_gap
  FROM ola_bookings
  WHERE booking_status = 'Success'
    AND driver_ratings IS NOT NULL 
    AND customer_rating IS NOT NULL;
  ```
- **DAX Implementation**:
  ```dax
  Rating Gap = [Average Driver Rating] - [Average Customer Rating]
  ```
- **Operational Nuances & Limitations**: Driver and customer ratings are subject to voluntary participation bias; unhappy riders or drivers are disproportionately more motivated to record extreme low scores than satisfied participants.
