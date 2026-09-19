-- ==============================================================================
-- File: 06_advanced_analysis.sql
-- Project: OLA Ride Analytics and Operations Intelligence
-- Author: Himanshu Sharma (GitHub: https://github.com/himanshuXsh)
-- Purpose: Advanced analytical queries utilizing CTEs, Window Functions, and Trend Analysis
-- Database Engine: MySQL 8.0+
-- ==============================================================================

USE ola_ride_analytics;

-- ==============================================================================
-- QUERY 1: Day-Over-Day (DoD) Revenue and Ride Growth Using LAG()
-- Business Context: Track daily revenue trajectory, ride volume, and identify
-- demand spikes or sudden operational drops.
-- SQL Concepts: CTE, SUM(), COUNT(), LAG() window function, NULLIF()
-- ==============================================================================
WITH daily_metrics AS (
    SELECT 
        ride_date,
        COUNT(booking_id) AS total_bookings,
        SUM(CASE WHEN booking_status = 'Success' THEN 1 ELSE 0 END) AS completed_rides,
        ROUND(SUM(CASE WHEN booking_status = 'Success' THEN booking_value ELSE 0 END), 2) AS daily_revenue
    FROM ola_bookings
    WHERE ride_date IS NOT NULL
    GROUP BY ride_date
)
SELECT 
    ride_date,
    total_bookings,
    completed_rides,
    daily_revenue,
    LAG(daily_revenue, 1) OVER (ORDER BY ride_date) AS prev_day_revenue,
    ROUND(
        (daily_revenue - LAG(daily_revenue, 1) OVER (ORDER BY ride_date)) * 100.0 / 
        NULLIF(LAG(daily_revenue, 1) OVER (ORDER BY ride_date), 0), 
        2
    ) AS dod_revenue_growth_pct,
    LAG(completed_rides, 1) OVER (ORDER BY ride_date) AS prev_day_completed_rides,
    (completed_rides - LAG(completed_rides, 1) OVER (ORDER BY ride_date)) AS dod_volume_change
FROM daily_metrics
ORDER BY ride_date;


-- ==============================================================================
-- QUERY 2: Peak Demand Hour and Operational Bottleneck Analysis
-- Business Context: Identify peak ride-hailing demand hours of the day and assess
-- whether completion rates degrade during peak hours due to driver shortage.
-- SQL Concepts: HOUR(), Conditional Aggregation, Ordering
-- ==============================================================================
SELECT 
    HOUR(ride_time) AS booking_hour,
    COUNT(*) AS total_ride_requests,
    SUM(CASE WHEN booking_status = 'Success' THEN 1 ELSE 0 END) AS completed_rides,
    SUM(CASE WHEN booking_status = 'Canceled by Customer' THEN 1 ELSE 0 END) AS customer_cancels,
    SUM(CASE WHEN booking_status = 'Canceled by Driver' THEN 1 ELSE 0 END) AS driver_cancels,
    SUM(CASE WHEN booking_status = 'Driver Not Found' THEN 1 ELSE 0 END) AS driver_not_found_count,
    ROUND(
        SUM(CASE WHEN booking_status = 'Success' THEN 1 ELSE 0 END) * 100.0 / NULLIF(COUNT(*), 0), 
        2
    ) AS completion_rate_pct,
    ROUND(AVG(CASE WHEN booking_status = 'Success' THEN booking_value ELSE NULL END), 2) AS avg_fare_inr
FROM ola_bookings
WHERE ride_time IS NOT NULL
GROUP BY HOUR(ride_time)
ORDER BY booking_hour ASC;


-- ==============================================================================
-- QUERY 3: Customer Value Deciles and Pareto (80/20) Analysis Using NTILE()
-- Business Context: Segment customers into 10 spending deciles to test if the top
-- 20% of users generate 80% of platform revenue.
-- SQL Concepts: CTE, NTILE(10), Window Aggregation, Percentile Revenue Contribution
-- ==============================================================================
WITH customer_spend AS (
    SELECT 
        customer_id,
        COUNT(booking_id) AS lifetime_bookings,
        SUM(CASE WHEN booking_status = 'Success' THEN booking_value ELSE 0 END) AS total_customer_spend
    FROM ola_bookings
    GROUP BY customer_id
),
customer_deciles AS (
    SELECT 
        customer_id,
        lifetime_bookings,
        total_customer_spend,
        NTILE(10) OVER (ORDER BY total_customer_spend DESC) AS spend_decile
    FROM customer_spend
)
SELECT 
    spend_decile,
    COUNT(customer_id) AS customers_in_bucket,
    ROUND(SUM(total_customer_spend), 2) AS decile_revenue_inr,
    ROUND(AVG(total_customer_spend), 2) AS avg_spend_per_customer_inr,
    ROUND(
        SUM(total_customer_spend) * 100.0 / (SELECT SUM(total_customer_spend) FROM customer_deciles),
        2
    ) AS pct_of_total_platform_revenue
FROM customer_deciles
GROUP BY spend_decile
ORDER BY spend_decile ASC;


-- ==============================================================================
-- QUERY 4: Top 10 High-Volume Route Corridors (Origin to Destination)
-- Business Context: Discover high-density travel corridors for surge management,
-- route optimization, and partner allocation.
-- SQL Concepts: Multiple Column Grouping, Conditional Metrics, DENSE_RANK()
-- ==============================================================================
WITH route_summary AS (
    SELECT 
        pickup_location,
        drop_location,
        COUNT(booking_id) AS total_route_requests,
        SUM(CASE WHEN booking_status = 'Success' THEN 1 ELSE 0 END) AS successful_trips,
        ROUND(AVG(CASE WHEN booking_status = 'Success' THEN ride_distance ELSE NULL END), 2) AS avg_distance_km,
        ROUND(SUM(CASE WHEN booking_status = 'Success' THEN booking_value ELSE 0 END), 2) AS total_route_revenue_inr,
        DENSE_RANK() OVER (ORDER BY COUNT(booking_id) DESC) AS route_rank
    FROM ola_bookings
    WHERE pickup_location IS NOT NULL 
      AND drop_location IS NOT NULL
    GROUP BY pickup_location, drop_location
)
SELECT 
    route_rank,
    pickup_location,
    drop_location,
    total_route_requests,
    successful_trips,
    ROUND(successful_trips * 100.0 / NULLIF(total_route_requests, 0), 2) AS corridor_completion_rate_pct,
    avg_distance_km,
    total_route_revenue_inr
FROM route_summary
WHERE route_rank <= 10
ORDER BY route_rank ASC;


-- ==============================================================================
-- QUERY 5: Turnaround Time (TAT) Impact on Ride Cancellation Probability
-- Business Context: Test the hypothesis that excessive vehicle arrival time (V_TAT)
-- triggers exponential increases in customer cancellations.
-- SQL Concepts: CASE Bucketing, Conditional Aggregation, Probability Index
-- ==============================================================================
SELECT 
    CASE 
        WHEN v_tat IS NULL THEN 'No Telemetry / Immediate Cancel'
        WHEN v_tat <= 120 THEN '0 - 2 mins (Fast Arrival)'
        WHEN v_tat <= 300 THEN '2 - 5 mins (Standard)'
        WHEN v_tat <= 600 THEN '5 - 10 mins (Moderate Delay)'
        ELSE '10+ mins (Severe Delay)'
    END AS arrival_tat_bucket,
    COUNT(*) AS total_bookings_in_bucket,
    SUM(CASE WHEN booking_status = 'Success' THEN 1 ELSE 0 END) AS completed_rides,
    SUM(CASE WHEN booking_status = 'Canceled by Customer' THEN 1 ELSE 0 END) AS customer_cancels,
    ROUND(
        SUM(CASE WHEN booking_status = 'Canceled by Customer' THEN 1 ELSE 0 END) * 100.0 / 
        NULLIF(COUNT(*), 0), 
        2
    ) AS customer_cancellation_rate_pct
FROM ola_bookings
GROUP BY arrival_tat_bucket
ORDER BY total_bookings_in_bucket DESC;


-- ==============================================================================
-- QUERY 6: Customer Ranking within Vehicle Category Using DENSE_RANK()
-- Business Context: Find the top 3 spenders for each distinct vehicle category.
-- SQL Concepts: CTE, DENSE_RANK() with PARTITION BY
-- ==============================================================================
WITH customer_vehicle_spend AS (
    SELECT 
        vehicle_type,
        customer_id,
        COUNT(booking_id) AS trips_completed,
        ROUND(SUM(booking_value), 2) AS category_spend_inr,
        DENSE_RANK() OVER (
            PARTITION BY vehicle_type 
            ORDER BY SUM(booking_value) DESC
        ) AS rank_within_fleet
    FROM ola_bookings
    WHERE booking_status = 'Success'
    GROUP BY vehicle_type, customer_id
)
SELECT 
    vehicle_type,
    rank_within_fleet,
    customer_id,
    trips_completed,
    category_spend_inr
FROM customer_vehicle_spend
WHERE rank_within_fleet <= 3
ORDER BY vehicle_type, rank_within_fleet;
