-- ==============================================================================
-- File: 05_analytical_views.sql
-- Project: OLA Ride Analytics and Operations Intelligence
-- Author: Himanshu Sharma (GitHub: https://github.com/himanshuXsh)
-- Purpose: Production analytical database views answering core business questions
-- Database Engine: MySQL 8.0+
-- ==============================================================================

USE ola_ride_analytics;

-- ==============================================================================
-- VIEW 1: Successful Bookings
-- Business Question: Which bookings completed successfully without cancellation?
-- SQL Concept: Basic Filtering (WHERE clause)
-- Expected Interpretation: The base universe of satisfied ride demand and realized revenue.
-- ==============================================================================
CREATE OR REPLACE VIEW vw_successful_bookings AS
SELECT 
    booking_id,
    ride_date,
    ride_time,
    customer_id,
    vehicle_type,
    pickup_location,
    drop_location,
    booking_value,
    payment_method,
    ride_distance,
    driver_ratings,
    customer_rating
FROM ola_bookings
WHERE booking_status = 'Success';


-- ==============================================================================
-- VIEW 2: Average Ride Distance by Vehicle Type
-- Business Question: What is the typical trip distance across different vehicle categories?
-- SQL Concept: Aggregation (AVG, ROUND, GROUP BY, ORDER BY)
-- Expected Interpretation: Demonstrates vehicle positioning (e.g., Bikes/Autos for short trips,
-- Prime Sedans/SUVs for long-distance commutes/airport runs).
-- ==============================================================================
CREATE OR REPLACE VIEW vw_avg_ride_distance_by_vehicle AS
SELECT 
    vehicle_type,
    COUNT(*) AS total_rides,
    ROUND(AVG(ride_distance), 2) AS avg_ride_distance_km,
    ROUND(MIN(ride_distance), 2) AS min_ride_distance_km,
    ROUND(MAX(ride_distance), 2) AS max_ride_distance_km
FROM ola_bookings
WHERE booking_status = 'Success'
GROUP BY vehicle_type
ORDER BY avg_ride_distance_km DESC;


-- ==============================================================================
-- VIEW 3: Total Bookings by Booking Status
-- Business Question: What is the distribution of booking outcomes across the platform?
-- SQL Concept: Aggregation with Subquery / Window share calculation
-- Expected Interpretation: Provides the primary platform funnel: completion rate vs cancellation rate.
-- ==============================================================================
CREATE OR REPLACE VIEW vw_bookings_by_status AS
SELECT 
    booking_status,
    COUNT(*) AS total_bookings,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM ola_bookings), 2) AS percentage_share
FROM ola_bookings
GROUP BY booking_status
ORDER BY total_bookings DESC;


-- ==============================================================================
-- VIEW 4: Top 5 Customers by Number of Rides
-- Business Question: Who are our highest frequency riders?
-- SQL Concept: Aggregation with ORDER BY and LIMIT
-- Expected Interpretation: Power users suitable for loyalty programs and subscription perks.
-- ==============================================================================
CREATE OR REPLACE VIEW vw_top_5_customers_by_rides AS
SELECT 
    customer_id,
    COUNT(booking_id) AS total_rides_booked,
    SUM(CASE WHEN booking_status = 'Success' THEN 1 ELSE 0 END) AS successful_rides,
    ROUND(SUM(CASE WHEN booking_status = 'Success' THEN 1 ELSE 0 END) * 100.0 / NULLIF(COUNT(booking_id), 0), 2) AS completion_rate_pct
FROM ola_bookings
GROUP BY customer_id
ORDER BY total_rides_booked DESC
LIMIT 5;


-- ==============================================================================
-- VIEW 5: Top Customers by Total Booking Value
-- Business Question: Which customers contribute the greatest gross merchandise value (GMV)?
-- SQL Concept: Conditional aggregation and monetary summation
-- Expected Interpretation: High-value enterprise/individual spenders driving platform revenue.
-- ==============================================================================
CREATE OR REPLACE VIEW vw_top_customers_by_revenue AS
SELECT 
    customer_id,
    COUNT(booking_id) AS total_completed_rides,
    ROUND(SUM(booking_value), 2) AS total_revenue_inr,
    ROUND(AVG(booking_value), 2) AS avg_order_value_inr
FROM ola_bookings
WHERE booking_status = 'Success'
GROUP BY customer_id
ORDER BY total_revenue_inr DESC;


-- ==============================================================================
-- VIEW 6: Driver Cancellations by Reason
-- Business Question: Why do drivers decline or abort assigned trips?
-- SQL Concept: Filtering NULLs, Aggregation, Percentage Distribution
-- Expected Interpretation: Highlights operational friction such as vehicle breakdown or personal issues.
-- ==============================================================================
CREATE OR REPLACE VIEW vw_driver_cancellations_by_reason AS
SELECT 
    canceled_rides_by_driver AS cancellation_reason,
    COUNT(*) AS cancellation_count,
    ROUND(COUNT(*) * 100.0 / (
        SELECT COUNT(*) FROM ola_bookings WHERE canceled_rides_by_driver IS NOT NULL
    ), 2) AS percentage_share
FROM ola_bookings
WHERE canceled_rides_by_driver IS NOT NULL
GROUP BY canceled_rides_by_driver
ORDER BY cancellation_count DESC;


-- ==============================================================================
-- VIEW 7: Customer Cancellation Count and Breakdown
-- Business Question: How many rides are cancelled by riders, and for what reported reasons?
-- SQL Concept: Grouping on customer cancellation taxonomy
-- Expected Interpretation: Identifies passenger pain points like driver delays or change of plans.
-- ==============================================================================
CREATE OR REPLACE VIEW vw_customer_cancellations_summary AS
SELECT 
    canceled_rides_by_customer AS cancellation_reason,
    COUNT(*) AS cancellation_count,
    ROUND(COUNT(*) * 100.0 / (
        SELECT COUNT(*) FROM ola_bookings WHERE canceled_rides_by_customer IS NOT NULL
    ), 2) AS percentage_share
FROM ola_bookings
WHERE canceled_rides_by_customer IS NOT NULL
GROUP BY canceled_rides_by_customer
ORDER BY cancellation_count DESC;


-- ==============================================================================
-- VIEW 8: Maximum and Minimum Driver Rating by Vehicle Type
-- Business Question: What are the rating extremes for drivers across categories, specifically Prime Sedan?
-- SQL Concept: Multi-column conditional aggregation (MIN/MAX)
-- Expected Interpretation: Quality variance across vehicle segments.
-- ==============================================================================
CREATE OR REPLACE VIEW vw_max_min_driver_ratings AS
SELECT 
    vehicle_type,
    ROUND(MIN(driver_ratings), 2) AS min_driver_rating,
    ROUND(MAX(driver_ratings), 2) AS max_driver_rating,
    ROUND(AVG(driver_ratings), 2) AS avg_driver_rating
FROM ola_bookings
WHERE booking_status = 'Success' 
  AND driver_ratings IS NOT NULL
GROUP BY vehicle_type
ORDER BY avg_driver_rating DESC;


-- ==============================================================================
-- VIEW 9: Average Customer Rating by Vehicle Type
-- Business Question: How well-rated are passengers across different vehicle categories?
-- SQL Concept: Aggregation with AVG and COUNT
-- Expected Interpretation: Assesses rider behavior and mutual platform etiquette across fleet tiers.
-- ==============================================================================
CREATE OR REPLACE VIEW vw_avg_customer_rating_by_vehicle AS
SELECT 
    vehicle_type,
    COUNT(customer_rating) AS rated_rides_count,
    ROUND(AVG(customer_rating), 2) AS avg_customer_rating
FROM ola_bookings
WHERE booking_status = 'Success'
  AND customer_rating IS NOT NULL
GROUP BY vehicle_type
ORDER BY avg_customer_rating DESC;


-- ==============================================================================
-- VIEW 10: Successful Revenue Summary
-- Business Question: What is the total realized revenue and average booking value from completed rides?
-- SQL Concept: Scalar aggregations with NULLIF
-- Expected Interpretation: Overall top-line GMV benchmark for the business.
-- ==============================================================================
CREATE OR REPLACE VIEW vw_successful_revenue_summary AS
SELECT 
    COUNT(*) AS total_successful_rides,
    ROUND(SUM(booking_value), 2) AS total_successful_revenue_inr,
    ROUND(AVG(booking_value), 2) AS avg_booking_value_inr,
    ROUND(SUM(ride_distance), 2) AS total_distance_km,
    ROUND(SUM(booking_value) / NULLIF(SUM(ride_distance), 0), 2) AS revenue_per_km_inr
FROM ola_bookings
WHERE booking_status = 'Success';


-- ==============================================================================
-- VIEW 11: Revenue by Payment Method
-- Business Question: Which settlement channels process the highest booking value?
-- SQL Concept: Aggregation, SUM, Percentage of Total
-- Expected Interpretation: Identifies digital payment adoption (UPI, Cards) vs physical cash.
-- ==============================================================================
CREATE OR REPLACE VIEW vw_revenue_by_payment_method AS
SELECT 
    COALESCE(payment_method, 'Unknown') AS payment_method,
    COUNT(*) AS transaction_count,
    ROUND(SUM(booking_value), 2) AS total_revenue_inr,
    ROUND(AVG(booking_value), 2) AS avg_ticket_size_inr,
    ROUND(SUM(booking_value) * 100.0 / (
        SELECT SUM(booking_value) FROM ola_bookings WHERE booking_status = 'Success'
    ), 2) AS revenue_share_pct
FROM ola_bookings
WHERE booking_status = 'Success'
GROUP BY payment_method
ORDER BY total_revenue_inr DESC;


-- ==============================================================================
-- VIEW 12: Revenue by Vehicle Type
-- Business Question: Which vehicle categories drive the majority of revenue?
-- SQL Concept: Aggregation with volume and revenue comparison
-- Expected Interpretation: Identifies revenue workhorses (e.g. Prime Sedan, Mini) vs low-cost options.
-- ==============================================================================
CREATE OR REPLACE VIEW vw_revenue_by_vehicle_type AS
SELECT 
    vehicle_type,
    COUNT(*) AS successful_rides,
    ROUND(SUM(booking_value), 2) AS total_revenue_inr,
    ROUND(AVG(booking_value), 2) AS avg_ride_fare_inr,
    ROUND(SUM(booking_value) * 100.0 / (
        SELECT SUM(booking_value) FROM ola_bookings WHERE booking_status = 'Success'
    ), 2) AS revenue_share_pct
FROM ola_bookings
WHERE booking_status = 'Success'
GROUP BY vehicle_type
ORDER BY total_revenue_inr DESC;


-- ==============================================================================
-- VIEW 13: Unified Cancellation Reason Analysis
-- Business Question: What is the consolidated view of all cancellations across parties?
-- SQL Concept: UNION ALL with originating party tagging
-- Expected Interpretation: Comprehensive portfolio view of cancellation drivers.
-- ==============================================================================
CREATE OR REPLACE VIEW vw_cancellation_reason_analysis AS
SELECT 
    'Customer' AS cancelled_by,
    canceled_rides_by_customer AS reason,
    COUNT(*) AS total_incidents
FROM ola_bookings
WHERE canceled_rides_by_customer IS NOT NULL
GROUP BY canceled_rides_by_customer

UNION ALL

SELECT 
    'Driver' AS cancelled_by,
    canceled_rides_by_driver AS reason,
    COUNT(*) AS total_incidents
FROM ola_bookings
WHERE canceled_rides_by_driver IS NOT NULL
GROUP BY canceled_rides_by_driver;


-- ==============================================================================
-- VIEW 14: Incomplete Ride Analysis
-- Business Question: How frequently do trips start but fail to reach the destination, and why?
-- SQL Concept: Conditional filtering and reason categorization
-- Expected Interpretation: Highlights in-transit drop-offs caused by breakdowns or emergencies.
-- ==============================================================================
CREATE OR REPLACE VIEW vw_incomplete_rides_analysis AS
SELECT 
    COALESCE(incomplete_rides_reason, 'Not Specified') AS incomplete_reason,
    COUNT(*) AS incident_count,
    ROUND(COUNT(*) * 100.0 / (
        SELECT COUNT(*) FROM ola_bookings WHERE incomplete_rides = 'Yes'
    ), 2) AS percentage_of_incomplete
FROM ola_bookings
WHERE incomplete_rides = 'Yes'
GROUP BY incomplete_rides_reason
ORDER BY incident_count DESC;


-- ==============================================================================
-- VIEW 15: Vehicle-Type Comprehensive Performance
-- Business Question: What is the complete operational scorecard for each vehicle tier?
-- SQL Concept: Multi-metric conditional aggregation
-- Expected Interpretation: 360-degree fleet evaluation (demand, completion, revenue, ratings).
-- ==============================================================================
CREATE OR REPLACE VIEW vw_vehicle_performance_metrics AS
SELECT 
    vehicle_type,
    COUNT(*) AS total_bookings,
    SUM(CASE WHEN booking_status = 'Success' THEN 1 ELSE 0 END) AS successful_bookings,
    SUM(CASE WHEN booking_status = 'Canceled by Customer' THEN 1 ELSE 0 END) AS customer_cancellations,
    SUM(CASE WHEN booking_status = 'Canceled by Driver' THEN 1 ELSE 0 END) AS driver_cancellations,
    ROUND(SUM(CASE WHEN booking_status = 'Success' THEN 1 ELSE 0 END) * 100.0 / NULLIF(COUNT(*), 0), 2) AS completion_rate_pct,
    ROUND(SUM(CASE WHEN booking_status = 'Success' THEN booking_value ELSE 0 END), 2) AS total_revenue_inr,
    ROUND(AVG(CASE WHEN booking_status = 'Success' THEN ride_distance ELSE NULL END), 2) AS avg_completed_distance_km,
    ROUND(AVG(CASE WHEN booking_status = 'Success' THEN driver_ratings ELSE NULL END), 2) AS avg_driver_rating,
    ROUND(AVG(CASE WHEN booking_status = 'Success' THEN customer_rating ELSE NULL END), 2) AS avg_customer_rating
FROM ola_bookings
GROUP BY vehicle_type
ORDER BY total_bookings DESC;


-- ==============================================================================
-- VIEW 16: Customer Booking Summary and Frequency
-- Business Question: How are customers distributed across ride frequency buckets?
-- SQL Concept: CTE with CASE segmentation
-- Expected Interpretation: Segment customer base into One-Time, Occasional, and Frequent Riders.
-- ==============================================================================
CREATE OR REPLACE VIEW vw_customer_booking_summary AS
WITH customer_totals AS (
    SELECT 
        customer_id,
        COUNT(booking_id) AS total_bookings,
        SUM(CASE WHEN booking_status = 'Success' THEN 1 ELSE 0 END) AS successful_bookings,
        SUM(CASE WHEN booking_status = 'Success' THEN booking_value ELSE 0 END) AS total_spent_inr
    FROM ola_bookings
    GROUP BY customer_id
)
SELECT 
    CASE 
        WHEN total_bookings = 1 THEN '1 Ride (One-Time)'
        WHEN total_bookings BETWEEN 2 AND 4 THEN '2-4 Rides (Occasional)'
        WHEN total_bookings BETWEEN 5 AND 9 THEN '5-9 Rides (Regular)'
        ELSE '10+ Rides (Power User)'
    END AS frequency_segment,
    COUNT(customer_id) AS total_customers,
    SUM(total_bookings) AS total_bookings_generated,
    ROUND(SUM(total_spent_inr), 2) AS total_revenue_generated_inr,
    ROUND(AVG(total_spent_inr), 2) AS avg_spend_per_customer_inr
FROM customer_totals
GROUP BY frequency_segment
ORDER BY total_bookings_generated DESC;


-- ==============================================================================
-- VIEW 17: Driver vs Customer Rating Comparison
-- Business Question: Is there a systematic divergence between how drivers rate customers vs vice versa?
-- SQL Concept: Metric delta computation and conditional aggregation
-- Expected Interpretation: Evaluates rating symmetry and satisfaction parity across fleets.
-- ==============================================================================
CREATE OR REPLACE VIEW vw_rating_comparison AS
SELECT 
    vehicle_type,
    COUNT(booking_id) AS evaluated_trips,
    ROUND(AVG(driver_ratings), 2) AS avg_driver_rating,
    ROUND(AVG(customer_rating), 2) AS avg_customer_rating,
    ROUND(AVG(driver_ratings) - AVG(customer_rating), 2) AS rating_gap,
    CASE 
        WHEN AVG(driver_ratings) > AVG(customer_rating) THEN 'Driver More Generous'
        WHEN AVG(driver_ratings) < AVG(customer_rating) THEN 'Customer More Generous'
        ELSE 'Parity'
    END AS sentiment_bias
FROM ola_bookings
WHERE booking_status = 'Success'
  AND driver_ratings IS NOT NULL 
  AND customer_rating IS NOT NULL
GROUP BY vehicle_type
ORDER BY evaluated_trips DESC;


-- ==============================================================================
-- VIEW 18: Operational Exceptions
-- Business Question: What trips experienced severe anomalies (extreme TAT, zero-fare completions, or incomplete rides)?
-- SQL Concept: Complex filter predicates detecting operational edge cases
-- Expected Interpretation: Triage queue for customer operations and driver investigations.
-- ==============================================================================
CREATE OR REPLACE VIEW vw_operational_exceptions AS
SELECT 
    booking_id,
    ride_date,
    customer_id,
    vehicle_type,
    booking_status,
    v_tat AS vehicle_arrival_tat_sec,
    c_tat AS customer_wait_tat_sec,
    booking_value,
    incomplete_rides,
    incomplete_rides_reason,
    CASE 
        WHEN incomplete_rides = 'Yes' THEN 'Incomplete Ride'
        WHEN booking_status = 'Success' AND (booking_value IS NULL OR booking_value = 0) THEN 'Zero-Fare Success'
        WHEN v_tat > 600 THEN 'Excessive Driver Arrival TAT (>10m)'
        WHEN c_tat > 300 THEN 'Excessive Customer Boarding TAT (>5m)'
        ELSE 'Other Exception'
    END AS exception_category
FROM ola_bookings
WHERE incomplete_rides = 'Yes'
   OR (booking_status = 'Success' AND (booking_value IS NULL OR booking_value = 0))
   OR v_tat > 600
   OR c_tat > 300;
