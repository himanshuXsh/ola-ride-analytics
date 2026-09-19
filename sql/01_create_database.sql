-- ==============================================================================
-- File: 01_create_database.sql
-- Project: OLA Ride Analytics and Operations Intelligence
-- Author: Himanshu Sharma (GitHub: https://github.com/himanshuXsh)
-- Purpose: Initialize the analytics database with optimal character set & collation
-- Database Engine: MySQL 8.0+
-- ==============================================================================

-- 1. Create the database if it doesn't already exist
-- utf8mb4 supports full Unicode including multilingual text and symbols.
CREATE DATABASE IF NOT EXISTS ola_ride_analytics
    DEFAULT CHARACTER SET utf8mb4
    DEFAULT COLLATE utf8mb4_unicode_ci;

-- 2. Switch context to the project database
USE ola_ride_analytics;

-- 3. Verify database configuration
SELECT 
    SCHEMA_NAME AS database_name,
    DEFAULT_CHARACTER_SET_NAME AS character_set,
    DEFAULT_COLLATION_NAME AS collation_name
FROM information_schema.SCHEMATA
WHERE SCHEMA_NAME = 'ola_ride_analytics';

-- 4. Session optimization settings for batch data ingestion
SET SESSION sql_mode = 'STRICT_TRANS_TABLES,NO_ENGINE_SUBSTITUTION';
SET SESSION time_zone = '+05:30'; -- IST (India Standard Time)
