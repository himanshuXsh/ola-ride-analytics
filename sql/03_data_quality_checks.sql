-- ==============================================================================
-- File: 03_data_quality_checks.sql
-- Project: OLA Ride Analytics and Operations Intelligence
-- Author: Himanshu Sharma (GitHub: https://github.com/himanshuXsh)
-- Purpose: Pre-cleaning and staging audit queries to evaluate data integrity
-- Database Engine: MySQL 8.0+
-- ==============================================================================

USE ola_ride_analytics;

-- ==============================================================================
-- SECTION 1: INDIVIDUAL DATA INTEGRITY AUDITS
-- ==============================================================================

-- ------------------------------------------------------------------------------
-- CHECK 1: Duplicate Booking IDs
-- Business Meaning: Booking IDs should be globally unique primary identifiers.
-- Expected Result: 0 rows. Any duplicate indicates repeated telemetry or double billing.
-- ------------------------------------------------------------------------------
SELECT 
    booking_id, 
    COUNT(*) AS occurrence_count
FROM raw_bookings
GROUP BY booking_id
HAVING COUNT(*) > 1;


-- ------------------------------------------------------------------------------
-- CHECK 2: Fully Duplicate Rows
-- Business Meaning: Completely identical records caused by ETL pipeline re-runs.
-- Remediation: De-duplicate before loading to production using ROW_NUMBER().
-- ------------------------------------------------------------------------------
SELECT 
    booking_id, customer_id, ride_date, ride_time, vehicle_type, COUNT(*) AS dup_count
FROM raw_bookings
GROUP BY booking_id, customer_id, ride_date, ride_time, vehicle_type
HAVING COUNT(*) > 1;


-- ------------------------------------------------------------------------------
-- CHECK 3: Missing or Null Customer IDs
-- Business Meaning: Customer transactions cannot be attributed without an ID.
-- Expected Result: 0 records.
-- ------------------------------------------------------------------------------
SELECT 
    COUNT(*) AS missing_customer_id_count
FROM raw_bookings
WHERE customer_id IS NULL 
   OR TRIM(customer_id) = '' 
   OR LOWER(customer_id) = 'null';


-- ------------------------------------------------------------------------------
-- CHECK 4: Missing or Blank Vehicle Types
-- Business Meaning: Fleet category must be populated to assess fleet utilization.
-- ------------------------------------------------------------------------------
SELECT 
    COUNT(*) AS missing_vehicle_type_count
FROM raw_bookings
WHERE vehicle_type IS NULL 
   OR TRIM(vehicle_type) = '' 
   OR LOWER(vehicle_type) = 'null';


-- ------------------------------------------------------------------------------
-- CHECK 5: Missing Booking Statuses
-- Business Meaning: The lifecycle state of a ride (Success/Canceled) is mandatory.
-- ------------------------------------------------------------------------------
SELECT 
    COUNT(*) AS missing_booking_status_count
FROM raw_bookings
WHERE booking_status IS NULL 
   OR TRIM(booking_status) = '' 
   OR LOWER(booking_status) = 'null';


-- ------------------------------------------------------------------------------
-- CHECK 6: Missing Payment Methods on Completed Rides
-- Business Meaning: Completed rides must have an associated settlement method.
-- Note: Cancelled rides legitimately have NULL payment methods.
-- ------------------------------------------------------------------------------
SELECT 
    booking_id, customer_id, booking_status, booking_value, payment_method
FROM raw_bookings
WHERE booking_status = 'Success'
  AND (payment_method IS NULL 
       OR TRIM(payment_method) = '' 
       OR LOWER(payment_method) = 'null');


-- ------------------------------------------------------------------------------
-- CHECK 7: Invalid Ratings Outside Valid 1.0 - 5.0 Range
-- Business Meaning: Rating scale is strictly between 1.00 and 5.00.
-- Non-completed rides with NULL ratings are legitimate and expected.
-- ------------------------------------------------------------------------------
SELECT 
    booking_id, 
    driver_ratings, 
    customer_rating
FROM raw_bookings
WHERE (
    driver_ratings IS NOT NULL 
    AND LOWER(driver_ratings) <> 'null' 
    AND (CAST(driver_ratings AS DECIMAL(4,2)) < 1.00 OR CAST(driver_ratings AS DECIMAL(4,2)) > 5.00)
) OR (
    customer_rating IS NOT NULL 
    AND LOWER(customer_rating) <> 'null' 
    AND (CAST(customer_rating AS DECIMAL(4,2)) < 1.00 OR CAST(customer_rating AS DECIMAL(4,2)) > 5.00)
);


-- ------------------------------------------------------------------------------
-- CHECK 8: Negative Booking Values
-- Business Meaning: Fare revenue cannot be negative.
-- ------------------------------------------------------------------------------
SELECT 
    booking_id, booking_status, booking_value
FROM raw_bookings
WHERE booking_value IS NOT NULL 
  AND LOWER(booking_value) <> 'null'
  AND CAST(booking_value AS DECIMAL(10,2)) < 0;


-- ------------------------------------------------------------------------------
-- CHECK 9: Negative Ride Distances
-- Business Meaning: Odometer distance traveled cannot be negative.
-- ------------------------------------------------------------------------------
SELECT 
    booking_id, booking_status, ride_distance
FROM raw_bookings
WHERE ride_distance IS NOT NULL 
  AND LOWER(ride_distance) <> 'null'
  AND CAST(ride_distance AS DECIMAL(8,2)) < 0;


-- ------------------------------------------------------------------------------
-- CHECK 10: Successful Rides With Missing or Zero Booking Value
-- Business Meaning: A completed ride with 0 or null revenue indicates meter failure.
-- ------------------------------------------------------------------------------
SELECT 
    booking_id, vehicle_type, ride_distance, booking_value
FROM raw_bookings
WHERE booking_status = 'Success'
  AND (
      booking_value IS NULL 
      OR LOWER(booking_value) = 'null'
      OR CAST(booking_value AS DECIMAL(10,2)) <= 0
  );


-- ------------------------------------------------------------------------------
-- CHECK 11: Cancelled Rides Missing Cancellation Reason
-- Business Meaning: Operational cancellations should have documented root cause
-- (either by driver or by customer).
-- ------------------------------------------------------------------------------
SELECT 
    booking_id, booking_status, canceled_rides_by_customer, canceled_rides_by_driver
FROM raw_bookings
WHERE booking_status IN ('Canceled by Customer', 'Canceled by Driver')
  AND (canceled_rides_by_customer IS NULL OR LOWER(canceled_rides_by_customer) = 'null')
  AND (canceled_rides_by_driver IS NULL OR LOWER(canceled_rides_by_driver) = 'null');


-- ------------------------------------------------------------------------------
-- CHECK 12: Invalid or Unknown Booking Statuses
-- Business Meaning: Verify whether all statuses match standard operational domain.
-- Standard domain: 'Success', 'Canceled by Customer', 'Canceled by Driver', 'Driver Not Found'.
-- ------------------------------------------------------------------------------
SELECT 
    booking_status, 
    COUNT(*) AS record_count
FROM raw_bookings
GROUP BY booking_status;


-- ==============================================================================
-- SECTION 2: COMPREHENSIVE DATA QUALITY AUDIT REPORT
-- This single query aggregates check results into a management report.
-- ==============================================================================
SELECT 
    'Duplicate Booking IDs' AS audit_check,
    COUNT(*) AS issue_count,
    CASE WHEN COUNT(*) = 0 THEN 'PASSED' ELSE 'FLAGGED FOR REVIEW' END AS audit_status,
    'De-duplicate by keeping most recent record' AS remediation_action
FROM (
    SELECT booking_id FROM raw_bookings GROUP BY booking_id HAVING COUNT(*) > 1
) sub_dup

UNION ALL

SELECT 
    'Missing Customer IDs',
    COUNT(*),
    CASE WHEN COUNT(*) = 0 THEN 'PASSED' ELSE 'CRITICAL' END,
    'Flag for ETL investigation; do not attribute to user metrics'
FROM raw_bookings
WHERE customer_id IS NULL OR TRIM(customer_id) = '' OR LOWER(customer_id) = 'null'

UNION ALL

SELECT 
    'Missing Vehicle Types',
    COUNT(*),
    CASE WHEN COUNT(*) = 0 THEN 'PASSED' ELSE 'CRITICAL' END,
    'Impute from fleet logs or assign to Unknown category'
FROM raw_bookings
WHERE vehicle_type IS NULL OR TRIM(vehicle_type) = '' OR LOWER(vehicle_type) = 'null'

UNION ALL

SELECT 
    'Missing Booking Status',
    COUNT(*),
    CASE WHEN COUNT(*) = 0 THEN 'PASSED' ELSE 'CRITICAL' END,
    'Investigate upstream status state-machine'
FROM raw_bookings
WHERE booking_status IS NULL OR TRIM(booking_status) = '' OR LOWER(booking_status) = 'null'

UNION ALL

SELECT 
    'Successful Rides Without Payment Method',
    COUNT(*),
    CASE WHEN COUNT(*) = 0 THEN 'PASSED' ELSE 'WARNING' END,
    'Check reconciliation with payment gateway logs'
FROM raw_bookings
WHERE booking_status = 'Success'
  AND (payment_method IS NULL OR TRIM(payment_method) = '' OR LOWER(payment_method) = 'null')

UNION ALL

SELECT 
    'Out of Bounds Ratings (<1 or >5)',
    COUNT(*),
    CASE WHEN COUNT(*) = 0 THEN 'PASSED' ELSE 'WARNING' END,
    'Set to NULL to prevent distorting score averages'
FROM raw_bookings
WHERE (
    driver_ratings IS NOT NULL 
    AND LOWER(driver_ratings) <> 'null' 
    AND (CAST(driver_ratings AS DECIMAL(4,2)) < 1.00 OR CAST(driver_ratings AS DECIMAL(4,2)) > 5.00)
) OR (
    customer_rating IS NOT NULL 
    AND LOWER(customer_rating) <> 'null' 
    AND (CAST(customer_rating AS DECIMAL(4,2)) < 1.00 OR CAST(customer_rating AS DECIMAL(4,2)) > 5.00)
)

UNION ALL

SELECT 
    'Negative Booking Values or Distances',
    COUNT(*),
    CASE WHEN COUNT(*) = 0 THEN 'PASSED' ELSE 'CRITICAL' END,
    'Reject or investigate refund ledger errors'
FROM raw_bookings
WHERE (booking_value IS NOT NULL AND LOWER(booking_value) <> 'null' AND CAST(booking_value AS DECIMAL(10,2)) < 0)
   OR (ride_distance IS NOT NULL AND LOWER(ride_distance) <> 'null' AND CAST(ride_distance AS DECIMAL(8,2)) < 0);
