-- ==============================================================================
-- File: 02_create_tables.sql
-- Project: OLA Ride Analytics and Operations Intelligence
-- Author: Himanshu Sharma (GitHub: https://github.com/himanshuXsh)
-- Purpose: Define staging (raw) and production (cleaned) tables with proper data types
-- Database Engine: MySQL 8.0+
-- ==============================================================================

USE ola_ride_analytics;

-- ------------------------------------------------------------------------------
-- 1. STAGING TABLE: raw_bookings
-- Permissive text-based schema used to import the raw CSV without load failure.
-- Raw values (including 'null' string literals and '#NAME?') are loaded as-is
-- for downstream auditing and cleaning.
-- ------------------------------------------------------------------------------
DROP TABLE IF EXISTS raw_bookings;

CREATE TABLE raw_bookings (
    ride_date                     VARCHAR(50),
    ride_time                     VARCHAR(50),
    booking_id                    VARCHAR(50),
    booking_status                VARCHAR(100),
    customer_id                   VARCHAR(50),
    vehicle_type                  VARCHAR(100),
    pickup_location               VARCHAR(255),
    drop_location                 VARCHAR(255),
    v_tat                         VARCHAR(50),  -- Vehicle Turnaround Time (arrival)
    c_tat                         VARCHAR(50),  -- Customer Turnaround Time (boarding)
    canceled_rides_by_customer    VARCHAR(255),
    canceled_rides_by_driver      VARCHAR(255),
    incomplete_rides              VARCHAR(50),
    incomplete_rides_reason       VARCHAR(255),
    booking_value                 VARCHAR(50),
    payment_method                VARCHAR(100),
    ride_distance                 VARCHAR(50),
    driver_ratings                VARCHAR(50),
    customer_rating               VARCHAR(50),
    vehicle_images                VARCHAR(255)  -- Contains '#NAME?' in raw Excel export
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- ------------------------------------------------------------------------------
-- 2. PRODUCTION ANALYTICAL TABLE: ola_bookings
-- Strictly typed, indexed schema optimized for business queries and Power BI.
-- Uses standard snake_case naming and explicit data constraints.
-- ------------------------------------------------------------------------------
DROP TABLE IF EXISTS ola_bookings;

CREATE TABLE ola_bookings (
    booking_id                    VARCHAR(50) NOT NULL,
    ride_date                     DATE,
    ride_time                     TIME,
    booking_status                VARCHAR(50) NOT NULL,
    customer_id                   VARCHAR(50) NOT NULL,
    vehicle_type                  VARCHAR(50) NOT NULL,
    pickup_location               VARCHAR(150),
    drop_location                 VARCHAR(150),
    v_tat                         INT NULL COMMENT 'Vehicle turnaround time in seconds',
    c_tat                         INT NULL COMMENT 'Customer turnaround time in seconds',
    canceled_rides_by_customer    VARCHAR(255) NULL,
    canceled_rides_by_driver      VARCHAR(255) NULL,
    incomplete_rides              VARCHAR(10) NULL COMMENT 'Yes or No',
    incomplete_rides_reason       VARCHAR(255) NULL,
    booking_value                 DECIMAL(10, 2) NULL COMMENT 'Fare in INR',
    payment_method                VARCHAR(50) NULL,
    ride_distance                 DECIMAL(8, 2) NULL COMMENT 'Distance in kilometers',
    driver_ratings                DECIMAL(3, 2) NULL COMMENT 'Rating from 1.00 to 5.00',
    customer_rating               DECIMAL(3, 2) NULL COMMENT 'Rating from 1.00 to 5.00',
    created_at                    TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    PRIMARY KEY (booking_id),
    INDEX idx_ride_date (ride_date),
    INDEX idx_booking_status (booking_status),
    INDEX idx_vehicle_type (vehicle_type),
    INDEX idx_customer_id (customer_id),
    INDEX idx_payment_method (payment_method)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ------------------------------------------------------------------------------
-- 3. Verification of Table Schemas
-- ------------------------------------------------------------------------------
DESCRIBE raw_bookings;
DESCRIBE ola_bookings;
