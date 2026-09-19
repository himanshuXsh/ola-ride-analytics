# 🚖 OLA Data Analyst Project: Power BI & SQL

An end-to-end data analytics project exploring ride-booking trends, vehicle performance, revenue metrics, cancellation reasons, and customer-driver ratings using **MySQL** and **Power BI**.

<p align="center">
  <img src="https://img.shields.io/badge/Database-MySQL-4479A1?style=for-the-badge&logo=mysql&logoColor=white"/>
  <img src="https://img.shields.io/badge/Business%20Intelligence-Power%20BI-F2C811?style=for-the-badge&logo=powerbi&logoColor=black"/>
  <img src="https://img.shields.io/badge/GitHub-himanshuXsh-181717?style=for-the-badge&logo=github&logoColor=white"/>
</p>

---

## 📌 Project Overview

This project provides an in-depth analysis of OLA ride-booking data in Bengaluru. By combining **SQL** for querying, data transformation, and KPI extraction with **Power BI** for interactive dashboards, this project delivers actionable operational insights into ride volume, fleet utilization, customer behavior, and cancellation dynamics.

---

## 🚀 Project Highlights

- **SQL Data Analysis**: 10 dedicated analytical views solving key business questions (ride completion, revenue metrics, cancellation analysis, ratings).
- **Power BI Interactive Dashboards**: 5 dedicated visual pages (Overall, Vehicle Type, Revenue, Cancellation, Ratings).
- **Operational Intelligence**: In-depth analysis of driver vs customer cancellation patterns and turnaround time bottlenecks.
- **Transactional Dataset**: Audited dataset containing 100,000+ ride records across 19 dimensions.

---

## 🗂️ Repository Structure

```text
ola-ride-analytics/
├── Bookings.csv                 # Raw ride-booking transactional dataset (100,000+ records)
├── Ola DA Project DEMO.gif      # Interactive Power BI dashboard walkthrough demo
├── Ola DA Project SQL.sql       # MySQL queries and views for 10 core business questions
├── Ola DA Project.pbix          # Full Power BI interactive report file
├── README.md                    # Project documentation, queries, and visual reports
└── images/                      # Dashboard screenshots and SQL query result captures
    ├── Screenshot 2024-12-15 195004.png
    ├── Screenshot 2024-12-15 201113.png
    ├── Screenshot 2024-12-15 201137.png
    ├── Screenshot 2024-12-15 201201.png
    ├── Screenshot 2024-12-15 201233.png
    └── SQL images/
        ├── Screenshot 2024-12-16 062720.png
        ├── Screenshot 2024-12-16 063354.png
        ├── Screenshot 2024-12-16 063653.png
        ├── Screenshot 2024-12-16 063859.png
        ├── Screenshot 2024-12-16 064122.png
        ├── Screenshot 2024-12-16 064314.png
        ├── Screenshot 2024-12-16 064820.png
        ├── Screenshot 2024-12-16 064923.png
        ├── Screenshot 2024-12-16 065052.png
        └── Screenshot 2024-12-16 065216.png
```

---

## 📊 Dataset Description

The dataset `Bookings.csv` contains transactional ride-booking records covering the following fields:

| Field Name | Description |
|:---|:---|
| `Date` | Date of the booking request |
| `Time` | Time of the ride booking |
| `Booking_ID` | Unique identifier for each ride |
| `Booking_Status` | Status: *Success*, *Canceled by Driver*, *Canceled by Customer*, *Driver Not Found* |
| `Customer_ID` | Unique customer identifier |
| `Vehicle_Type` | Fleet type: *Auto, Bike, eBike, Mini, Prime Sedan, Prime Plus, Prime SUV* |
| `Pickup_Location` | Starting urban location in Bengaluru |
| `Drop_Location` | Destination urban location in Bengaluru |
| `V_TAT` | Vehicle Turnaround Time (arrival time to pickup point) |
| `C_TAT` | Customer Turnaround Time (passenger boarding wait time) |
| `Canceled_Rides_by_Customer` | Documented reason for customer cancellation |
| `Canceled_Rides_by_Driver` | Documented reason for driver cancellation |
| `Incomplete_Rides` | Flag indicating whether ride was terminated mid-trip (*Yes / No*) |
| `Incomplete_Rides_Reason` | Reason for incomplete ride (*Vehicle Breakdown*, *Customer Demand*, etc.) |
| `Booking_Value` | Ride fare amount in INR |
| `Payment_Method` | Payment mode: *UPI, Cash, Credit Card, Debit Card* |
| `Ride_Distance` | Total trip distance in kilometers |
| `Driver_Ratings` | Rating given to driver (1.0 to 5.0) |
| `Customer_Rating` | Rating given to customer (1.0 to 5.0) |

---

## 💻 SQL Analysis & Queries

The SQL script `Ola DA Project SQL.sql` initializes the database and creates dedicated analytical views:

```sql
create database Ola;
use Ola;
```

### 1. Retrieve all successful bookings:
```sql
create view Success_Booking as
select * from bookings 
where Booking_Status="Success";

select * from Success_Booking;
```
<p align="center">
  <img src="images/SQL images/Screenshot 2024-12-16 062720.png" alt="Successful Bookings" width="85%"/>
</p>

---

### 2. Find the average ride distance for each vehicle type:
```sql
create view average_ride_distance_for_each_vehicle as
select Vehicle_Type, AVG(Ride_Distance) as booking
from bookings 
group by Vehicle_Type;

select * from average_ride_distance_for_each_vehicle;
```
<p align="center">
  <img src="images/SQL images/Screenshot 2024-12-16 063354.png" alt="Average Ride Distance" width="85%"/>
</p>

---

### 3. Get the total number of cancelled rides by customers:
```sql
create view number_of_cancelled_rides as
SELECT COUNT(*) FROM bookings 
WHERE Booking_Status = 'Canceled by Customer';

select * from number_of_cancelled_rides;
```
<p align="center">
  <img src="images/SQL images/Screenshot 2024-12-16 063653.png" alt="Cancelled Rides by Customer" width="85%"/>
</p>

---

### 4. List the top 5 customers who booked the highest number of rides:
```sql
create view top_5_customers as
select Customer_ID, count(Booking_ID) as total_rides from bookings
group by Customer_ID
order by total_rides desc limit 5;

select * from top_5_customers;
```
<p align="center">
  <img src="images/SQL images/Screenshot 2024-12-16 063859.png" alt="Top 5 Customers" width="85%"/>
</p>

---

### 5. Get the number of rides cancelled by drivers due to personal and car-related issues:
```sql
create view rides_cancelled_by_drivers as
select count(*) from bookings
where Canceled_Rides_by_Driver = 'Personal & Car related issue';

select * from rides_cancelled_by_drivers;
```
<p align="center">
  <img src="images/SQL images/Screenshot 2024-12-16 064122.png" alt="Driver Cancellations" width="85%"/>
</p>

---

### 6. Find the maximum and minimum driver ratings for Prime Sedan bookings:
```sql
Create View Max_Min_Driver_Rating As
SELECT MAX(Driver_Ratings) as max_rating, MIN(Driver_Ratings) as min_rating 
FROM bookings 
WHERE Vehicle_Type = 'Prime Sedan';

select * from Max_Min_Driver_Rating;
```
<p align="center">
  <img src="images/SQL images/Screenshot 2024-12-16 064314.png" alt="Prime Sedan Ratings" width="85%"/>
</p>

---

### 7. Retrieve all rides where payment was made using UPI:
```sql
create view UPI_payments as
select * from bookings
where Payment_Method='UPI';

select * from UPI_payments;
```
<p align="center">
  <img src="images/SQL images/Screenshot 2024-12-16 064820.png" alt="UPI Payments" width="85%"/>
</p>

---

### 8. Find the average customer rating per vehicle type:
```sql
create view avg_rating_for_v_type as
select Vehicle_Type, round(avg(Customer_Rating), 1) as avg_rating_for_v_type 
from bookings 
group by Vehicle_Type;

select * from avg_rating_for_v_type;
```
<p align="center">
  <img src="images/SQL images/Screenshot 2024-12-16 064923.png" alt="Customer Rating per Vehicle" width="85%"/>
</p>

---

### 9. Calculate the total booking value of rides completed successfully:
```sql
create view total_booking_value_rides_completed as
SELECT SUM(Booking_Value) as total_successful_value FROM bookings WHERE
Booking_Status = 'Success';

select * from total_booking_value_rides_completed;
```
<p align="center">
  <img src="images/SQL images/Screenshot 2024-12-16 065052.png" alt="Total Successful Booking Value" width="85%"/>
</p>

---

### 10. List all incomplete rides along with the reason:
```sql
create view Incomplete_Rides_Reason As
SELECT Booking_ID, Incomplete_Rides_Reason FROM bookings 
WHERE Incomplete_Rides ='Yes';

select * from Incomplete_Rides_Reason;
```
<p align="center">
  <img src="images/SQL images/Screenshot 2024-12-16 065216.png" alt="Incomplete Rides Reason" width="85%"/>
</p>

---

## 📈 Power BI Dashboards

### 🎬 Interactive Dashboard Walkthrough
<p align="center">
  <img src="Ola DA Project DEMO.gif" alt="OLA Dashboard Demo" width="95%"/>
</p>

---

### 1. Overall Performance View
- **Ride Volume Over Time**: Visualizes daily fluctuations and trends in ride bookings.
- **Booking Status Breakdown**: Displays the distribution of booking statuses (Success, Cancelled, etc.).
<p align="center">
  <img src="images/Screenshot 2024-12-15 195004.png" alt="Overall Dashboard" width="95%"/>
</p>

---

### 2. Vehicle Type Analysis
- **Top Vehicle Types by Ride Volume**: Identifies the most popular vehicle categories.
- **Completed vs Cancelled Rides**: Compares fulfillment rates across vehicle segments.
<p align="center">
  <img src="images/Screenshot 2024-12-15 201113.png" alt="Vehicle Type Dashboard" width="95%"/>
</p>

---

### 3. Revenue & Payment Analysis
- **Revenue by Payment Method**: Visualizes total revenue processed through UPI, Cash, Credit Card, and Debit Card.
- **Top 5 Customers by Booking Value**: Identifies the highest spending accounts.
- **Ride Distance Distribution Per Day**: Displays mileage trends across the month.
<p align="center">
  <img src="images/Screenshot 2024-12-15 201137.png" alt="Revenue Dashboard" width="95%"/>
</p>

---

### 4. Cancellation Diagnostics
- **Cancelled Rides Reasons (Customer)**: Analyzes primary reasons behind customer-initiated cancellations.
- **Cancelled Rides Reasons (Driver)**: Details primary causes behind driver-initiated cancellations.
<p align="center">
  <img src="images/Screenshot 2024-12-15 201201.png" alt="Cancellation Dashboard" width="95%"/>
</p>

---

### 5. Ratings Analysis
- **Driver Ratings**: Displays the distribution of scores awarded to drivers.
- **Customer Ratings**: Displays the distribution of scores awarded to customers.
<p align="center">
  <img src="images/Screenshot 2024-12-15 201233.png" alt="Ratings Dashboard" width="95%"/>
</p>

---

## 🔍 Dashboard Insights

### Key Insights:
1. **Ride Volume Trends**: Identifies peak commute hours and demand cycles throughout the week.
2. **Booking Status Insights**: Pinpoints the overall ratio of completed versus aborted trips.
3. **Vehicle Type Performance**: Shows that micro-mobility (Auto, Bike) drives trip volume while Prime categories drive revenue.
4. **Revenue Patterns**: UPI and Cash dominate payment volume, while credit cards are preferred for high-fare trips.
5. **Cancellation Drivers**: Driver cancellations are led by vehicle/personal issues; customer cancellations correlate with pickup delay.

### Interactive Features:
- **Drill-through Options**: Explore detailed breakdowns by vehicle type and customer account.
- **Custom Slicers**: Dynamic filtering across dates, fleet types, and payment methods.
- **KPI Cards**: Real-time high-level summaries of total bookings, revenue, and ratings.

---

## 🛠️ How to Use

1. **Clone the Repository**:
   ```bash
   git clone https://github.com/himanshuXsh/ola-ride-analytics.git
   cd ola-ride-analytics
   ```

2. **Execute SQL Queries**:
   - Open your SQL client (MySQL Workbench, phpMyAdmin, or MySQL CLI).
   - Load and execute `Ola DA Project SQL.sql`.

3. **Explore Power BI Dashboard**:
   - Open `Ola DA Project.pbix` in **Power BI Desktop**.
   - Interact with filters, slicers, and drill-through pages.

---

## 📁 File Details

<details>
<summary>Click to view file details and downloads</summary>

- **File Name**: `Ola DA Project.pbix` (Power BI Report) — `~3.96 MB`
- **File Name**: `Bookings.csv` (Dataset) — `~15.5 MB`
- **File Name**: `Ola DA Project SQL.sql` (SQL Queries) — `~3.2 KB`
- **File Name**: `Ola DA Project DEMO.gif` (Demo Walkthrough) — `~2.3 MB`

</details>

---

## 👤 Author

**Himanshu Sharma**  
Final-year AI/ML student from Delhi, India, interested in data analytics, artificial intelligence, backend development, and business intelligence.

- **GitHub**: [https://github.com/himanshuXsh](https://github.com/himanshuXsh)
- **Repository**: [https://github.com/himanshuXsh/ola-ride-analytics](https://github.com/himanshuXsh/ola-ride-analytics)

---

## 📄 Disclaimer

> “This is an educational portfolio analysis based on the available dataset and is not official internal OLA data.”
