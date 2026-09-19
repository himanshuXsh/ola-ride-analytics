-- ==============================================================================
-- File: 04_cleaning_logic.sql
-- Project: OLA Ride Analytics and Operations Intelligence
-- Author: Himanshu Sharma (GitHub: https://github.com/himanshuXsh)
-- Purpose: Production ETL pipeline to sanitize, cast, and load raw data into ola_bookings
-- Database Engine: MySQL 8.0+
-- ==============================================================================

USE ola_ride_analytics;

-- ------------------------------------------------------------------------------
-- 1. Truncate production table prior to fresh ingestion
-- ------------------------------------------------------------------------------
TRUNCATE TABLE ola_bookings;

-- ------------------------------------------------------------------------------
-- 2. Clean & Load Pipeline with CTE and Row De-duplication
-- 
-- Business Rules & Transformations:
--  a. De-duplication: Window function ROW_NUMBER() ensures unique booking_id.
--  b. String 'null' conversion: Literal strings 'null', 'NULL', '', and whitespace
--     are converted to proper SQL NULLs using NULLIF and CASE expressions.
--  c. Date/Time Parsing: Extracts DATE and TIME components safely.
--  d. Numeric Type Casting: Converts string metrics to DECIMAL/INT types.
--  e. Incomplete Rides: Standardizes to 'Yes' / 'No' / NULL.
--  f. Excel Artifacts: Ignores corrupt spreadsheet artifact '#NAME?' from vehicle_images.
-- ------------------------------------------------------------------------------

INSERT INTO ola_bookings (
    booking_id,
    ride_date,
    ride_time,
    booking_status,
    customer_id,
    vehicle_type,
    pickup_location,
    drop_location,
    v_tat,
    c_tat,
    canceled_rides_by_customer,
    canceled_rides_by_driver,
    incomplete_rides,
    incomplete_rides_reason,
    booking_value,
    payment_method,
    ride_distance,
    driver_ratings,
    customer_rating
)
WITH ranked_records AS (
    SELECT 
        TRIM(booking_id) AS raw_booking_id,
        TRIM(ride_date) AS raw_ride_date,
        TRIM(ride_time) AS raw_ride_time,
        TRIM(booking_status) AS raw_booking_status,
        TRIM(customer_id) AS raw_customer_id,
        TRIM(vehicle_type) AS raw_vehicle_type,
        TRIM(pickup_location) AS raw_pickup_location,
        TRIM(drop_location) AS raw_drop_location,
        TRIM(v_tat) AS raw_v_tat,
        TRIM(c_tat) AS raw_c_tat,
        TRIM(canceled_rides_by_customer) AS raw_canceled_by_cust,
        TRIM(canceled_rides_by_driver) AS raw_canceled_by_driver,
        TRIM(incomplete_rides) AS raw_incomplete_rides,
        TRIM(incomplete_rides_reason) AS raw_incomplete_reason,
        TRIM(booking_value) AS raw_booking_value,
        TRIM(payment_method) AS raw_payment_method,
        TRIM(ride_distance) AS raw_ride_distance,
        TRIM(driver_ratings) AS raw_driver_ratings,
        TRIM(customer_rating) AS raw_customer_rating,
        ROW_NUMBER() OVER (
            PARTITION BY TRIM(booking_id) 
            ORDER BY TRIM(ride_date) DESC, TRIM(ride_time) DESC
        ) AS row_num
    FROM raw_bookings
    WHERE booking_id IS NOT NULL 
      AND TRIM(booking_id) <> '' 
      AND LOWER(TRIM(booking_id)) <> 'null'
)
SELECT 
    raw_booking_id AS booking_id,
    
    -- Date standardisation: Handles both 'YYYY-MM-DD HH:MM:SS' and 'YYYY-MM-DD'
    CASE 
        WHEN raw_ride_date IS NULL OR LOWER(raw_ride_date) = 'null' OR raw_ride_date = '' THEN NULL
        ELSE STR_TO_DATE(SUBSTRING_INDEX(raw_ride_date, ' ', 1), '%Y-%m-%d')
    END AS ride_date,

    -- Time standardisation: Handles 'HH:MM:SS'
    CASE 
        WHEN raw_ride_time IS NULL OR LOWER(raw_ride_time) = 'null' OR raw_ride_time = '' THEN NULL
        ELSE CAST(raw_ride_time AS TIME)
    END AS ride_time,

    raw_booking_status AS booking_status,
    raw_customer_id AS customer_id,
    raw_vehicle_type AS vehicle_type,
    
    NULLIF(raw_pickup_location, 'null') AS pickup_location,
    NULLIF(raw_drop_location, 'null') AS drop_location,

    -- Vehicle Turnaround Time (arrival)
    CASE 
        WHEN raw_v_tat IS NULL OR LOWER(raw_v_tat) = 'null' OR raw_v_tat = '' THEN NULL
        ELSE CAST(raw_v_tat AS SIGNED)
    END AS v_tat,

    -- Customer Turnaround Time (boarding wait)
    CASE 
        WHEN raw_c_tat IS NULL OR LOWER(raw_c_tat) = 'null' OR raw_c_tat = '' THEN NULL
        ELSE CAST(raw_c_tat AS SIGNED)
    END AS c_tat,

    -- Cancellation Reasons
    CASE 
        WHEN raw_canceled_by_cust IS NULL OR LOWER(raw_canceled_by_cust) = 'null' OR raw_canceled_by_cust = '' THEN NULL
        ELSE raw_canceled_by_cust
    END AS canceled_rides_by_customer,

    CASE 
        WHEN raw_canceled_by_driver IS NULL OR LOWER(raw_canceled_by_driver) = 'null' OR raw_canceled_by_driver = '' THEN NULL
        ELSE raw_canceled_by_driver
    END AS canceled_rides_by_driver,

    -- Incomplete Rides indicator
    CASE 
        WHEN raw_incomplete_rides IS NULL OR LOWER(raw_incomplete_rides) = 'null' OR raw_incomplete_rides = '' THEN NULL
        ELSE raw_incomplete_rides
    END AS incomplete_rides,

    CASE 
        WHEN raw_incomplete_reason IS NULL OR LOWER(raw_incomplete_reason) = 'null' OR raw_incomplete_reason = '' THEN NULL
        ELSE raw_incomplete_reason
    END AS incomplete_rides_reason,

    -- Booking Value: If ride was cancelled, value may represent requested quote or 0
    CASE 
        WHEN raw_booking_value IS NULL OR LOWER(raw_booking_value) = 'null' OR raw_booking_value = '' THEN NULL
        ELSE CAST(raw_booking_value AS DECIMAL(10,2))
    END AS booking_value,

    -- Payment Method: NULL for non-settled rides
    CASE 
        WHEN raw_payment_method IS NULL OR LOWER(raw_payment_method) = 'null' OR raw_payment_method = '' THEN NULL
        ELSE raw_payment_method
    END AS payment_method,

    -- Ride Distance: Sanitized to numeric
    CASE 
        WHEN raw_ride_distance IS NULL OR LOWER(raw_ride_distance) = 'null' OR raw_ride_distance = '' THEN 0.00
        ELSE CAST(raw_ride_distance AS DECIMAL(8,2))
    END AS ride_distance,

    -- Ratings: Nullified if out of valid bounds [1.00, 5.00]
    CASE 
        WHEN raw_driver_ratings IS NULL OR LOWER(raw_driver_ratings) = 'null' OR raw_driver_ratings = '' THEN NULL
        WHEN CAST(raw_driver_ratings AS DECIMAL(3,2)) BETWEEN 1.00 AND 5.00 
            THEN CAST(raw_driver_ratings AS DECIMAL(3,2))
        ELSE NULL
    END AS driver_ratings,

    CASE 
        WHEN raw_customer_rating IS NULL OR LOWER(raw_customer_rating) = 'null' OR raw_customer_rating = '' THEN NULL
        WHEN CAST(raw_customer_rating AS DECIMAL(3,2)) BETWEEN 1.00 AND 5.00 
            THEN CAST(raw_customer_rating AS DECIMAL(3,2))
        ELSE NULL
    END AS customer_rating

FROM ranked_records
WHERE row_num = 1;

-- ------------------------------------------------------------------------------
-- 3. Post-Cleaning Row Count & Integrity Verification
-- ------------------------------------------------------------------------------
SELECT 
    COUNT(*) AS total_clean_records,
    COUNT(DISTINCT booking_id) AS unique_bookings,
    COUNT(DISTINCT customer_id) AS unique_customers,
    MIN(ride_date) AS earliest_date,
    MAX(ride_date) AS latest_date
FROM ola_bookings;
