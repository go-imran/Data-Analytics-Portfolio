/*
================================================================================
Database: Project_Hospitality_management
================================================================================
Summary:
This SQL script handles hotel booking data and prepares it for analytics.
It includes:
1. Database creation and switching context
2. Table creation for raw data and replica for cleaning
3. Bulk import of CSV data
4. Data cleaning: type conversions for dates and numeric fields
5. Customer insights: segmentation, loyalty, cancellation analysis, and lead time

Purpose:
- Ensure hotel booking data is properly stored and structured
- Clean and convert raw data for accurate analytics
- Identify high-value customers, top markets, and cancellation trends

Risks / Considerations:
- Improper CSV format can cause import errors
- Date conversion failures if formats differ
- Dividing by total cancellation count requires non-zero denominator
================================================================================
*/

--================================================================================
-- SECTION 1: DATABASE CREATION AND CONTEXT SWITCH
-- Purpose: Create database for the project and ensure we are using it
-- Risks: Attempting to create an existing database may throw error if IF NOT EXISTS is not used
--================================================================================
CREATE DATABASE Project_Hospitality_management;
USE Project_Hospitality_management;

--================================================================================
-- SECTION 2: DROP EXISTING TABLE IF NEEDED
-- Purpose: Remove old HotelBookings table to avoid conflicts
-- Risk: Data will be lost if the table exists
--================================================================================
DROP TABLE IF EXISTS dbo.HotelBookings;

--================================================================================
-- SECTION 3: CREATE TABLE HotelBookings
-- Purpose: Store all hotel booking records with descriptive columns
-- Risks: Wrong data types may require later conversion; primary key conflicts if duplicate BookingID exists
--================================================================================
CREATE TABLE HotelBookings (
    BookingID INT PRIMARY KEY,                           
    Hotel VARCHAR(100),                                  
    BookingDate VARCHAR(100),                            
    ArrivalDate VARCHAR(100),                            
    LeadTime INT,                                        
    Nights INT,                                          
    Guests INT,                                          
    DistributionChannel VARCHAR(100),                    
    CustomerType VARCHAR(50),                            
    Country VARCHAR(100),                                
    DepositType VARCHAR(50),                             
    AvgDailyRate DECIMAL(10, 2),                         
    Status VARCHAR(50),                                  
    StatusUpdate VARCHAR(100),                           
    Cancelled BIT,                                       
    Revenue VARCHAR(50),                                 
    RevenueLoss VARCHAR(50)                               
);

--================================================================================
-- SECTION 4: BULK IMPORT CSV DATA
-- Purpose: Load raw hotel booking data into HotelBookings table
-- Risks: File path or CSV format issues may cause failure; missing rows if first row not skipped
--================================================================================
BULK INSERT HotelBookings
FROM 'C:\SQLData\Hotel_Management_Data.csv'
WITH (
    FORMAT = 'CSV',
    FIRSTROW = 2,
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '\n',
    CODEPAGE = '65001',
    TABLOCK
);

--================================================================================
-- SECTION 5: CREATE REPLICA TABLE FOR DATA CLEANING
-- Purpose: Keep original data intact while cleaning and converting types
--================================================================================
CREATE TABLE HotelBookings_replica (
    BookingID INT PRIMARY KEY,                           
    Hotel VARCHAR(100),                                  
    BookingDate VARCHAR(100),                            
    ArrivalDate VARCHAR(100),                            
    LeadTime INT,                                        
    Nights INT,                                          
    Guests INT,                                          
    DistributionChannel VARCHAR(100),                    
    CustomerType VARCHAR(50),                            
    Country VARCHAR(100),                                
    DepositType VARCHAR(50),                             
    AvgDailyRate DECIMAL(10, 2),                         
    Status VARCHAR(50),                                  
    StatusUpdate VARCHAR(100),                           
    Cancelled BIT,                                       
    Revenue VARCHAR(50),                                 
    RevenueLoss VARCHAR(50)                               
);

-- Bulk insert into replica table
BULK INSERT HotelBookings_replica
FROM 'C:\SQLData\Hotel Management Data.csv'
WITH (
    FORMAT = 'CSV',
    FIRSTROW = 2,
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '\n',
    CODEPAGE = '65001',
    TABLOCK
);

--================================================================================
-- SECTION 6: DATA CLEANING - CONVERT DATES AND NUMERIC FIELDS
-- Purpose: Convert string dates to proper DATE type and revenue fields to DECIMAL
-- Risks: Invalid formats will result in NULLs; ensure TRY_CONVERT used to avoid errors
--================================================================================
-- Add new date columns for conversion
ALTER TABLE HotelBookings_replica
ADD BookingDate_new DATE,
    ArrivalDate_new DATE,
    StatusUpdate_new DATE;

-- Convert StatusUpdate
UPDATE HotelBookings_replica
SET StatusUpdate_new = TRY_CONVERT(DATE, StatusUpdate, 103)
WHERE StatusUpdate_new IS NULL;

-- Drop old column and rename new one
ALTER TABLE HotelBookings_replica
DROP COLUMN StatusUpdate;

EXEC sp_rename 'HotelBookings_replica.StatusUpdate_new', 'StatusUpdate', 'COLUMN';

-- Convert ArrivalDate
UPDATE HotelBookings_replica
SET ArrivalDate_new = TRY_CONVERT(DATE, ArrivalDate, 103)
WHERE ArrivalDate_new IS NULL;

EXEC sp_rename 'HotelBookings_replica.ArrivalDate_new', 'ArrivalDate', 'COLUMN';

-- Convert RevenueLoss to DECIMAL
ALTER TABLE HotelBookings_replica
ADD RevenueLoss_new DECIMAL(10,2);

UPDATE HotelBookings_replica
SET RevenueLoss_new = TRY_CONVERT(DECIMAL(10,2), RevenueLoss)
WHERE RevenueLoss_new IS NULL;

ALTER TABLE HotelBookings_replica
DROP COLUMN RevenueLoss;

-- Rename Revenue column if needed (assuming similar cleaning steps)
-- EXEC sp_rename 'HotelBookings_replica.Revenue_new', 'Revenue', 'COLUMN';

--================================================================================
-- SECTION 7: CUSTOMER INSIGHTS & SEGMENTATION
-- Purpose: Analyze customer behavior, loyalty, and cancellations
-- Risks: Aggregations may mislead if NULLs exist; cancellation percentages require non-zero total
--================================================================================

-- Highest average revenue per booking by customer type
SELECT CustomerType, AVG(Revenue) AS avg_revenue
FROM HotelBookings_replica
GROUP BY CustomerType
ORDER BY avg_revenue DESC;

-- Average nights stayed per customer type
SELECT CustomerType, AVG(Nights) AS avg_nights
FROM HotelBookings_replica
GROUP BY CustomerType
ORDER BY avg_nights ASC;

-- Top 10 countries by Average Daily Rate (ADR)
SELECT TOP(10) Country, AVG(AvgDailyRate) AS avg_of_avg_daily_rate
FROM HotelBookings_replica
GROUP BY Country
ORDER BY avg_of_avg_daily_rate DESC;

-- Top 10 countries by booking volume & cancellation rate
DECLARE @total INT;
SELECT @total = COUNT(Cancelled) 
FROM HotelBookings_replica 
WHERE Cancelled = 1;

WITH tab1 AS (
    SELECT Country, (CAST(COUNT(Cancelled) AS DECIMAL)/@total)*100 AS booking_percentages
    FROM HotelBookings_replica
    WHERE Cancelled = 1
    GROUP BY Country
),
tab2 AS (
    SELECT Country, COUNT(BookingID) AS Booking_count
    FROM HotelBookings_replica
    GROUP BY Country
)
SELECT TOP(10) tab2.Country, tab2.Booking_count, ISNULL(tab1.booking_percentages, 0) AS cancellation_rate
FROM tab2
LEFT JOIN tab1 ON tab1.Country = tab2.Country
ORDER BY tab2.Booking_count DESC;

-- Customer type with highest cancellation rate
SELECT CustomerType, (CAST(COUNT(Cancelled) AS DECIMAL)/@total)*100 AS cancellation_percentages
FROM HotelBookings_replica
WHERE Cancelled = 1
GROUP BY CustomerType
ORDER BY cancellation_percentages DESC;

-- Average lead time by customer type (for cancelled bookings)
SELECT CustomerType, AVG(LeadTime) AS avg_lead_time
FROM HotelBookings_replica
WHERE Cancelled = 1
GROUP BY CustomerType
ORDER BY avg_lead_time DESC;

-- Median lead time for each customer type
SELECT DISTINCT CustomerType,
PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY LeadTime ASC)
OVER (PARTITION BY CustomerType) AS median_lead_time
FROM HotelBookings_replica;

/*
================================================================================
SECTION: Revenue & Advanced Analytics, Customer Behavior & Seasonality
================================================================================
Summary:
This portion analyzes hotel revenue, booking patterns, customer behavior, and seasonality.
It includes:
1. Clustering countries by booking behavior
2. Guests-based analysis (e.g., >3 guests)
3. Revenue management (monthly, daily, net revenue)
4. Revenue loss and cancellation insights
5. ADR volatility & standard deviation analysis
6. Revenue per guest and seasonal trends
7. Comparison of ADR before/after cancellations
8. Weekly arrival analysis

Purpose:
- Identify top revenue sources (countries, customer types, channels)
- Analyze booking patterns for operational & pricing decisions
- Evaluate ADR volatility and revenue loss trends
- Support seasonality and channel strategy decisions

Risks / Considerations:
- Aggregation queries may be heavy on large datasets
- Nulls or zero values in Revenue/Guests can skew results
- Month-based analysis assumes all dates are valid
- Index creation improves performance but may affect concurrent inserts
================================================================================
*/

--================================================================================
-- Cluster countries by similar booking behaviors: Guests, LeadTime, ADR
-- Purpose: Pre-aggregation for k-means clustering or segmentation
-- Risks: Small sample countries may distort percentiles
--================================================================================
SELECT Country, avg_guest,
    PERCENTILE_CONT(0.25) WITHIN GROUP(ORDER BY avg_guest) OVER() 
FROM (
    SELECT Country,
        AVG(Guests) AS avg_guest,
        AVG(LeadTime) AS avg_leadTime,
        AVG(AvgDailyRate) AS avg_of_avg_dailyRate
    FROM HotelBookings_replica
    GROUP BY Country
) tab1;

--================================================================================
-- Analyze bookings with more than 3 guests and their revenue impact
-- Purpose: Identify impact of larger groups on revenue and revenue loss
-- Risks: Divide by zero avoided by using COUNT(*) cast to DECIMAL
--================================================================================
CREATE NONCLUSTERED INDEX ix_guest ON HotelBookings_replica(Guests);

SELECT 
    (COUNT(CASE WHEN Guests>3 THEN BookingID ELSE NULL END) / CAST(COUNT(*) AS DECIMAL))*100 AS Booking_percentages,
    SUM(CASE WHEN Guests>3 THEN Revenue ELSE 0 END) AS total_Rev,
    SUM(CASE WHEN Guests>3 THEN RevenueLoss ELSE 0 END) AS total_Rev_loss
FROM HotelBookings_replica;

--================================================================================
-- Revenue Management: Total Revenue, Revenue Loss, Net Revenue by month
-- Purpose: Analyze monthly financial performance and cancellations
-- Risks: LEFT JOIN may return NULL for months without cancellations; RevenueLoss may be negative
--================================================================================
CREATE NONCLUSTERED INDEX ix_ArrivalDate ON HotelBookings_replica(ArrivalDate) INCLUDE (Revenue);
CREATE NONCLUSTERED INDEX ix_StatusUpdate ON HotelBookings_replica(StatusUpdate) INCLUDE (RevenueLoss);

DROP INDEX ix_StatusUpdate ON HotelBookings_replica;

WITH tab1 AS (
    SELECT MONTH(ArrivalDate) AS Month_number, SUM(Revenue) AS Total_Rev
    FROM HotelBookings_replica
    GROUP BY MONTH(ArrivalDate)
),
tab2 AS (
    SELECT MONTH(StatusUpdate) AS Month_number, SUM(RevenueLoss) AS Total_RevLoss
    FROM HotelBookings_replica
    GROUP BY MONTH(StatusUpdate)
)
SELECT 
    tab1.Month_number, 
    tab1.Total_Rev, 
    tab2.Total_RevLoss,
    (tab1.Total_Rev + ISNULL(tab2.Total_RevLoss, 0)) AS Net_Rev
FROM tab1
LEFT JOIN tab2 ON tab1.Month_number = tab2.Month_number
ORDER BY tab1.Month_number ASC;

--================================================================================
-- Using temporary tables for revenue analysis
-- Purpose: Efficient intermediate storage for monthly revenue joins
--================================================================================
SELECT MONTH(ArrivalDate) AS Month_number, SUM(Revenue) AS Total_Rev
INTO #tab3
FROM HotelBookings_replica
GROUP BY MONTH(ArrivalDate);

SELECT MONTH(StatusUpdate) AS Month_number, SUM(RevenueLoss) AS Total_RevLoss
INTO #tab4
FROM HotelBookings_replica
GROUP BY MONTH(StatusUpdate);

CREATE NONCLUSTERED INDEX ix_month_tab1 ON #tab3(Month_number);
CREATE NONCLUSTERED INDEX ix_month_tab2 ON #tab4(Month_number);

SELECT 
    t1.Month_number,
    t1.Total_Rev,
    t2.Total_RevLoss
FROM #tab3 t1
LEFT JOIN #tab4 t2 ON t1.Month_number = t2.Month_number
ORDER BY t1.Month_number;

--================================================================================
-- Average revenue loss due to cancellations per month
-- Purpose: Quantify financial impact of cancellations monthly
--================================================================================
SELECT MONTH(StatusUpdate) AS Month_Number,
       AVG(RevenueLoss) AS AvgRevLoss
FROM HotelBookings_replica
WHERE Cancelled = 1
GROUP BY MONTH(StatusUpdate)
ORDER BY MONTH(StatusUpdate) ASC;

--================================================================================
-- Distribution channel associated with highest revenue loss
-- Purpose: Identify channels with high cancellation/revenue loss risk
--================================================================================
SELECT DistributionChannel, ABS(SUM(RevenueLoss)) AS Total_revLoss
FROM HotelBookings_replica
GROUP BY DistributionChannel
ORDER BY Total_revLoss DESC;

--================================================================================
-- Top 10 days with highest net revenue
-- Purpose: Identify peak revenue days for operational planning
--================================================================================
SELECT TOP(10) ArrivalDate, SUM(Net_Rev) AS actual_netRev
FROM (
    SELECT ArrivalDate, (Revenue+RevenueLoss) AS Net_Rev
    FROM HotelBookings_replica
) tab1
GROUP BY ArrivalDate
ORDER BY actual_netRev DESC;

--================================================================================
-- Country with highest revenue per night
-- Purpose: Understand which markets are more profitable per night stayed
--================================================================================
SELECT Country, (SUM(Revenue)/SUM(Nights)) AS RevPerNights
FROM HotelBookings_replica
WHERE Nights>0
GROUP BY Country
ORDER BY RevPerNights DESC;

--================================================================================
-- ADR volatility: Coefficient of Variation (std/mean) by month
-- Purpose: Assess pricing consistency and rate fluctuation
--================================================================================
SELECT MONTH(ArrivalDate) AS MonthNumber,
       (STDEVP(AvgDailyRate)*1.0/AVG(AvgDailyRate)) AS CoefficientVariance
FROM HotelBookings_replica
WHERE AvgDailyRate>0
GROUP BY MONTH(ArrivalDate)
ORDER BY MONTH(ArrivalDate) ASC;

--================================================================================
-- Customer type variability in ADR
-- Purpose: Identify customer types contributing most to rate variability
--================================================================================
SELECT CustomerType, STDEVP(AvgDailyRate) AS StandardDeviations
FROM HotelBookings_replica
GROUP BY CustomerType
ORDER BY StandardDeviations DESC;

--================================================================================
-- Revenue per guest and seasonality analysis
-- Purpose: Understand revenue trends across months and seasons
--================================================================================
WITH tab1 AS (
    SELECT MONTH(ArrivalDate) AS Month_Number, (SUM(Revenue)/SUM(Guests)) AS RevPerGuest
    FROM HotelBookings_replica
    WHERE Guests>0
    GROUP BY MONTH(ArrivalDate)
),
tab2 AS (
    SELECT Month_Number,
        CASE
            WHEN Month_Number BETWEEN 3 AND 5 THEN 'Spring'
            WHEN Month_Number BETWEEN 6 AND 8 THEN 'Summer'
            WHEN Month_Number BETWEEN 9 AND 11 THEN 'Autumn'
            ELSE 'Winter'
        END AS Seasons
    FROM tab1
)
SELECT tab2.Month_Number, tab2.Seasons, tab1.RevPerGuest
FROM tab2 
LEFT JOIN tab1 ON tab2.Month_Number = tab1.Month_Number
ORDER BY tab2.Month_Number;

--================================================================================
-- Compare avg ADR before and after cancellations by customer type
-- Purpose: Analyze how cancellations impact average daily rate by customer type
--================================================================================
WITH cte AS (
    SELECT CustomerType, AVG(AvgDailyRate) AS Total_AVD_before_cancell
    FROM HotelBookings_replica
    WHERE Cancelled=0
    GROUP BY CustomerType
),
cte2 AS (
    SELECT CustomerType, AVG(AvgDailyRate) AS Total_AVD_after_cancell
    FROM HotelBookings_replica
    WHERE Cancelled=1
    GROUP BY CustomerType
)
SELECT c2.CustomerType, c.Total_AVD_before_cancell, c2.Total_AVD_after_cancell
FROM cte2 c2 
FULL OUTER JOIN cte c ON c.CustomerType=c2.CustomerType;

--================================================================================
-- Day-of-week analysis: highest average arrivals
-- Purpose: Identify which days have peak guest arrivals
--================================================================================
WITH cte AS(
    SELECT DATENAME(WEEKDAY, ArrivalDate) AS Day_of_week,
           ArrivalDate,
           COUNT(*) AS Arrival_count
    FROM HotelBookings_replica
    WHERE Cancelled = 0
    GROUP BY DATENAME(WEEKDAY, ArrivalDate), ArrivalDate
)
SELECT Day_of_week, AVG(Arrival_count) AS Avg_count
FROM cte
GROUP BY Day_of_week
ORDER BY Avg_count DESC;

--================================================================================
-- Weekly arrival percentage distribution
-- Purpose: Visualize distribution of arrivals across weekdays
--================================================================================
SELECT DATENAME(WEEKDAY, ArrivalDate) AS Days_of_week, 
       COUNT(ArrivalDate) AS Arrival_count 
INTO temp_tab
FROM HotelBookings_replica
GROUP BY DATENAME(WEEKDAY, ArrivalDate);

DECLARE @Totalcount DECIMAL(10,2);
SELECT @Totalcount = SUM(Arrival_count) FROM temp_tab;

SELECT Days_of_week, (Arrival_count*100/@Totalcount) AS Arrival_percentage
FROM temp_tab;


--================================================================================
-- Average length of stay per customer type
-- Purpose: Identify customer behavior and typical stay duration
--================================================================================
SELECT CustomerType, AVG(Nights) AS avg_Stay
FROM HotelBookings_replica
GROUP BY CustomerType;

--================================================================================
-- Overbooked days analysis
-- Assumption: Maximum hotel capacity is 350 bookings
-- Purpose: Identify operational risk days
--================================================================================
SELECT ArrivalDate, TotalBooking,
    CASE
        WHEN TotalBooking>350 THEN 'Overbooked'
        ELSE 'RegularBooking'
    END AS BookingCapacity
FROM (
    SELECT ArrivalDate, COUNT(DISTINCT BookingID) AS TotalBooking
    FROM HotelBookings_replica
    GROUP BY ArrivalDate
) hotel;

--================================================================================
-- Longest lead times per distribution channel
-- Purpose: Understand customer booking advance behavior per channel
--================================================================================
SELECT DistributionChannel,
       MAX(LeadTime) AS LongestLeadTime
FROM HotelBookings_replica
GROUP BY DistributionChannel
ORDER BY LongestLeadTime DESC;

--================================================================================
-- Busiest months by total guest count
-- Purpose: Identify peak operational months
--================================================================================
SELECT TOP(3) MONTH(ArrivalDate) AS MonthNumber,
       SUM(Guests) AS GuestsNumber
FROM HotelBookings_replica
GROUP BY MONTH(ArrivalDate)
ORDER BY GuestsNumber DESC;

--================================================================================
-- Percentage of short (1-6 nights) vs long stays (7+ nights)
-- Purpose: Customer stay pattern analysis for operational planning
--================================================================================
DECLARE @ShortStays DECIMAL(10,2);
DECLARE @LongStays DECIMAL(10,2);
DECLARE @TotalStays DECIMAL(10,2);

SELECT @ShortStays = COUNT(*) FROM HotelBookings_replica WHERE Nights>0 AND Nights<7;
SELECT @LongStays  = COUNT(*) FROM HotelBookings_replica WHERE Nights>=7;
SELECT @TotalStays = COUNT(*) FROM HotelBookings_replica WHERE Nights IS NOT NULL;

SELECT 
  CAST((@ShortStays*100.0)/@TotalStays AS DECIMAL(10,2)) AS ShortStays_Percentage,
  CAST((@LongStays*100.0)/@TotalStays AS DECIMAL(10,2)) AS LongStays_Percentage;

--================================================================================
-- Booking peaks and average lead time
-- Purpose: Assess if lead times are sufficient for operational prep
--================================================================================
SELECT MONTH(ArrivalDate) AS MonthNumber,
       AVG(LeadTime) AS AvgLeadTime,
       COUNT(BookingID) AS NumOfBookings
FROM HotelBookings_replica
GROUP BY MONTH(ArrivalDate)
ORDER BY NumOfBookings DESC;

--================================================================================
-- Standard deviation of guest count per day (Z-score analysis)
-- Purpose: Identify high-variance days and operational risk
--================================================================================
WITH GuestCount AS (
    SELECT ArrivalDate, SUM(Guests) AS TotalGuests
    FROM HotelBookings_replica
    GROUP BY ArrivalDate
),
GuestStdv AS (
    SELECT AVG(TotalGuests) AS MeanGuest, STDEV(TotalGuests) AS TotalGuestStdv
    FROM GuestCount
),
ZScore AS (
    SELECT g.ArrivalDate, g.TotalGuests,
           ROUND(((g.TotalGuests - s.MeanGuest)/s.TotalGuestStdv), 3) AS Zscore
    FROM GuestCount g
    CROSS JOIN GuestStdv s
)
SELECT z.ArrivalDate, z.TotalGuests, z.Zscore,
       CASE
           WHEN z.Zscore>2 THEN 'Unusually high guest'
           WHEN z.Zscore<-2 THEN 'Unusually low guest'
           ELSE 'Normal'
       END AS GuestQuantity
FROM ZScore z
ORDER BY z.Zscore DESC;

--================================================================================
-- Cumulative revenue per month
-- Purpose: Track revenue trends and growth over time
--================================================================================
SELECT YEAR(ArrivalDate) AS ArrivalYear,
       MONTH(ArrivalDate) AS ArrivalMonth,
       SUM(Revenue) AS MonthlyRevenue,
       SUM(SUM(Revenue)) OVER (
           ORDER BY YEAR(ArrivalDate), MONTH(ArrivalDate)
           ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
       ) AS CumulativeRevenue
FROM HotelBookings_replica
GROUP BY YEAR(ArrivalDate), MONTH(ArrivalDate)
ORDER BY YEAR(ArrivalDate), MONTH(ArrivalDate);

--================================================================================
-- Average number of guests per booking by month
-- Purpose: Identify months with largest group sizes
--================================================================================
WITH Guest AS (
    SELECT MONTH(ArrivalDate) AS MonthNumber, SUM(Guests) AS TotalGuest
    FROM HotelBookings_replica
    GROUP BY MONTH(ArrivalDate)
),
Booking AS (
    SELECT MONTH(ArrivalDate) AS MonthNumber, COUNT(BookingID) AS TotalBookings
    FROM HotelBookings_replica 
    GROUP BY MONTH(ArrivalDate)
)
SELECT TOP(2) g.MonthNumber,
       CAST((g.TotalGuest/b.TotalBookings) AS DECIMAL(10,2)) AS AvgGuests
FROM Guest g
JOIN Booking b ON g.MonthNumber=b.MonthNumber
ORDER BY AvgGuests DESC;

--================================================================================
-- Month-over-month growth in net revenue
-- Purpose: Track monthly revenue growth trends
--================================================================================
SELECT YearValue, MonthNumber, TotalRev, LagRev,
       CAST(((TotalRev-LagRev)/LagRev) AS DECIMAL(10,2)) AS MonthOverMonth
FROM(
    SELECT YEAR(ArrivalDate) AS YearValue, MONTH(ArrivalDate) AS MonthNumber,
           SUM(Revenue) AS TotalRev,
           LAG(SUM(Revenue)) OVER (PARTITION BY YEAR(ArrivalDate) ORDER BY MONTH(ArrivalDate)) AS LagRev
    FROM HotelBookings_replica
    GROUP BY YEAR(ArrivalDate), MONTH(ArrivalDate)
) AS LagRevByMonth;

--================================================================================
-- 3-month moving average of ADR
-- Purpose: Identify short-term trends in average daily rate
--================================================================================
SELECT YEAR(ArrivalDate) AS YearValue,
       MONTH(ArrivalDate) AS MonthNumber,
       AVG(AvgDailyRate) AS AvgADR,
       ROW_NUMBER() OVER (PARTITION BY YEAR(ArrivalDate) ORDER BY YEAR(ArrivalDate), MONTH(ArrivalDate), AVG(AvgDailyRate)) AS RowNum,
       CASE
           WHEN ROW_NUMBER() OVER (PARTITION BY YEAR(ArrivalDate) ORDER BY YEAR(ArrivalDate), MONTH(ArrivalDate), AVG(AvgDailyRate)) >= 3
           THEN AVG(AVG(AvgDailyRate)) OVER (
                    PARTITION BY YEAR(ArrivalDate)
                    ORDER BY MONTH(ArrivalDate)
                    ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
                )
           ELSE NULL
       END AS MovingAvg
FROM HotelBookings_replica
GROUP BY YEAR(ArrivalDate), MONTH(ArrivalDate);

--================================================================================
-- Forecast next month's revenue (linear trend, next month Sept 2017)
-- Purpose: Predict revenue using linear regression on past 15 months
-- Risks: Assumes linear trend; external shocks/events not considered
--================================================================================
WITH BaseTable AS (
    SELECT YEAR(ArrivalDate) AS YearValue,
           MONTH(ArrivalDate) AS MonthNumber,
           ROW_NUMBER() OVER (ORDER BY YEAR(ArrivalDate), MONTH(ArrivalDate)) AS MonthIndex,
           AVG(Revenue) AS AvgRevenue,
           (ROW_NUMBER() OVER (ORDER BY YEAR(ArrivalDate), MONTH(ArrivalDate)) * AVG(Revenue)) AS XY,
           POWER(ROW_NUMBER() OVER (ORDER BY YEAR(ArrivalDate), MONTH(ArrivalDate)), 2) AS X_MultiplyBy_X
    FROM HotelBookings_replica
    GROUP BY YEAR(ArrivalDate), MONTH(ArrivalDate)
),
TotalXY AS (
    SELECT SUM(XY) AS SumXY,
           SUM(X_MultiplyBy_X) AS SumX_MultiplyBy_X,
           SUM(MonthIndex) AS SumX,
           (SUM(MonthIndex) * SUM(MonthIndex)) AS SumX_MultiplyBy_SumX,
           SUM(AvgRevenue) AS SumY
    FROM BaseTable
),
Find_ab AS (
    SELECT (((15*SumXY)-(SumX*SumY))/((15*SumX_MultiplyBy_X)-(SumX_MultiplyBy_SumX))) AS a,
           ((SumY-(((15*SumXY)-(SumX*SumY))/((15*SumX_MultiplyBy_X)-(SumX_MultiplyBy_SumX))*SumX))/15) AS b
    FROM TotalXY
)
SELECT DISTINCT (a*16 + b) AS ExpectedAvgRevForSept2017
FROM Find_ab;


--================================================================================
-- Seasonality: Which months consistently peak in bookings over the last 3 years
--================================================================================
WITH MonthlyData AS (
  SELECT 
    MONTH(ArrivalDate) AS MonthNumber,
    COUNT(CASE WHEN YEAR(ArrivalDate) = 2015 THEN BookingID END) AS Bookings_2015,
    COUNT(CASE WHEN YEAR(ArrivalDate) = 2016 THEN BookingID END) AS Bookings_2016,
    COUNT(CASE WHEN YEAR(ArrivalDate) = 2017 THEN BookingID END) AS Bookings_2017
  FROM HotelBookings_replica
  GROUP BY MONTH(ArrivalDate)
),
FullTable AS (
  SELECT *, 
    (SELECT COUNT(BookingID)/36.0 FROM HotelBookings_replica) AS AvgBookingFor3Years
  FROM MonthlyData
)
SELECT 
   F.MonthNumber,
   CASE WHEN F.Bookings_2015=0 THEN 0 ELSE CAST(((F.Bookings_2015-F.AvgBookingFor3Years)/F.AvgBookingFor3Years)*100 AS DECIMAL(10,2)) END AS Seasonality_peak_2015,
   CASE WHEN F.Bookings_2016=0 THEN 0 ELSE CAST(((F.Bookings_2016-F.AvgBookingFor3Years)/F.AvgBookingFor3Years)*100 AS DECIMAL(10,2)) END AS Seasonality_peak_2016,
   CASE WHEN F.Bookings_2017=0 THEN 0 ELSE CAST(((F.Bookings_2017-F.AvgBookingFor3Years)/F.AvgBookingFor3Years)*100 AS DECIMAL(10,2)) END AS Seasonality_peak_2017
FROM FullTable F
ORDER BY F.MonthNumber;

--================================================================================
-- Compare EXPECTED vs ACTUAL revenue per month
--================================================================================
SELECT 
  MONTH(ArrivalDate) AS MonthNumber,
  (ABS(SUM(RevenueLoss))+SUM(Revenue)) AS ExpectedRevenue,
  SUM(Revenue) AS ActualRevenue,
  ABS(SUM(RevenueLoss)) AS LostRevenue,
  CAST((SUM(Revenue)/(ABS(SUM(RevenueLoss))+SUM(Revenue)))*100 AS DECIMAL(10,2)) AS Revenue_Percentage
FROM HotelBookings_replica
GROUP BY MONTH(ArrivalDate)
ORDER BY MONTH(ArrivalDate);

--================================================================================
-- Daily booking trend using 7-day rolling averages
--================================================================================
SELECT
   YEAR(ArrivalDate) AS ArrivalYear,
   ArrivalDate,
   COUNT(BookingID) AS Daily_Booking,
   ROW_NUMBER() OVER(ORDER BY ArrivalDate) AS RowValue,
   CASE
      WHEN (ROW_NUMBER() OVER(ORDER BY ArrivalDate))>=7 THEN AVG(COUNT(BookingID)) OVER(ORDER BY ArrivalDate ROWS BETWEEN 6 PRECEDING AND CURRENT ROW) 
	  ELSE NULL 
   END AS Rolling_7DayAvg
FROM HotelBookings_replica
GROUP BY YEAR(ArrivalDate), ArrivalDate;

--================================================================================
-- ADR anomaly detection (>2 SD from mean)
--================================================================================
DECLARE @SDForADR DECIMAL(10,2);
DECLARE @MEANForADR DECIMAL(10,2);

SELECT @SDForADR = STDEV(AvgDailyRate) FROM HotelBookings_replica;
SELECT @MEANForADR = AVG(AvgDailyRate) FROM HotelBookings_replica;

SELECT AvgDailyRate,
  CASE
    WHEN AvgDailyRate>(@MEANForADR+2*@SDForADR) OR AvgDailyRate<(@MEANForADR-2*@SDForADR) THEN 'OUTLIER'
    ELSE 'NORMAL'
  END AS ANOMALIES
FROM HotelBookings_replica;

--================================================================================
-- Customer type predictability (low ADR CV)
--================================================================================
SELECT
   CustomerType, 
   AVG(AvgDailyRate) AS ADR,
   CAST(STDEV(AvgDailyRate) AS DECIMAL(10,2)) AS STD_ADR, 
   CAST(STDEV(AvgDailyRate) / NULLIF(AVG(AvgDailyRate),0) AS DECIMAL(10,2)) AS CV_ADR
FROM HotelBookings_replica
GROUP BY CustomerType;

--================================================================================
-- Hotel-wise ADR and Revenue comparison
--================================================================================
SELECT
    Hotel,
	AVG(AvgDailyRate) AS AVGADR,
    ROUND(SUM(Revenue)/1000000.0,2) AS TotalREV_Million
FROM HotelBookings_replica
GROUP BY Hotel;

--================================================================================
-- Revenue per distribution channel & identify highest revenue channel
--================================================================================
SELECT 
	DistributionChannel,
	SUM(Revenue)/COUNT(*) AS RevPerGuest,
	MAX(SUM(Revenue)*1.0/COUNT(*)) OVER() AS HighestRev
FROM HotelBookings_replica
GROUP BY DistributionChannel;

--================================================================================
-- Cancellation percentages by CustomerType & Country
--================================================================================
DECLARE @TotalCancelled DECIMAL(10,2);
SELECT @TotalCancelled = SUM(CAST(Cancelled AS DECIMAL)) FROM HotelBookings_replica;

SELECT 
	CustomerType,
	ISNULL(Country,'UNKNOWN') AS COUNTRY,
	SUM(CAST(Cancelled AS DECIMAL(10,2))) AS TotalCancellation,
	SUM(CAST(Cancelled AS DECIMAL(10,2)))*100/@TotalCancelled AS TotalCancellationPercentage
FROM HotelBookings_replica
GROUP BY CustomerType, Country
HAVING SUM(CAST(Cancelled AS DECIMAL(10,2))) <> 0
ORDER BY CustomerType;

--================================================================================
-- Lead time difference: Local vs International customers
-- Assumption: United Kingdom is local
--================================================================================
SELECT
	AVG(CASE WHEN Country='United Kingdom' THEN LeadTime ELSE NULL END) AS LocalAVGLeadTime,
	AVG(CASE WHEN Country<>'United Kingdom' THEN LeadTime ELSE NULL END) AS InternationalAVGLeadTime
FROM HotelBookings_replica;

--================================================================================
-- Market share by country (based on number of bookings)
--================================================================================
SELECT 
	ISNULL(Country,'UNKNOWN') AS COUNTRY,
	COUNT(BookingID)*100.0/(SELECT COUNT(*) FROM HotelBookings_replica WHERE Cancelled<>1) AS BookingPercentage
FROM HotelBookings_replica
WHERE Cancelled<>1
GROUP BY Country
ORDER BY BookingPercentage DESC;

--================================================================================
-- Top 5 customer segments by net profit per booking
--================================================================================
SELECT
	CustomerType,
	SUM(Revenue) AS TotalREV,
	ABS(SUM(RevenueLoss)) AS TotalREVLoss,
	SUM(Revenue)-ABS(SUM(RevenueLoss)) AS NetProfit,
	CAST(SUM(Revenue)-ABS(SUM(RevenueLoss)) AS FLOAT)/NULLIF(COUNT(*),0) AS ProfitPerBooking
FROM HotelBookings_replica
GROUP BY CustomerType
ORDER BY NetProfit DESC;

--================================================================================
-- 1. Correlation between LeadTime and Cancellation Rate
--================================================================================
SELECT 
    CASE 
        WHEN LeadTime BETWEEN 0 AND 73 THEN 1
        WHEN LeadTime BETWEEN 74 AND 147 THEN 2
        WHEN LeadTime BETWEEN 148 AND 221 THEN 3
        WHEN LeadTime BETWEEN 222 AND 295 THEN 4
        WHEN LeadTime BETWEEN 296 AND 369 THEN 5
        WHEN LeadTime BETWEEN 370 AND 443 THEN 6
        WHEN LeadTime BETWEEN 444 AND 517 THEN 7
        WHEN LeadTime BETWEEN 518 AND 591 THEN 8
        WHEN LeadTime BETWEEN 592 AND 665 THEN 9
        WHEN LeadTime BETWEEN 666 AND 737 THEN 10
        ELSE 'Unknown'
    END AS LeadTimeBinList,
    CASE 
        WHEN LeadTime BETWEEN 0 AND 73 THEN '0-73'
        WHEN LeadTime BETWEEN 74 AND 147 THEN '74-147'
        WHEN LeadTime BETWEEN 148 AND 221 THEN '148-221'
        WHEN LeadTime BETWEEN 222 AND 295 THEN '222-295'
        WHEN LeadTime BETWEEN 296 AND 369 THEN '296-369'
        WHEN LeadTime BETWEEN 370 AND 443 THEN '370-443'
        WHEN LeadTime BETWEEN 444 AND 517 THEN '444-517'
        WHEN LeadTime BETWEEN 518 AND 591 THEN '518-591'
        WHEN LeadTime BETWEEN 592 AND 665 THEN '592-665'
        WHEN LeadTime BETWEEN 666 AND 737 THEN '666-737'
        ELSE 'Unknown'
    END AS LeadTimeBin,
    COUNT(*) AS TotalBookings,
    SUM(CAST(Cancelled AS INT)) AS Cancellations,
    ROUND(SUM(CAST(Cancelled AS FLOAT))*100.0 / COUNT(*), 2) AS CancellationRate
FROM HotelBookings_replica
GROUP BY 
    CASE 
        WHEN LeadTime BETWEEN 0 AND 73 THEN '0-73'
        WHEN LeadTime BETWEEN 74 AND 147 THEN '74-147'
        WHEN LeadTime BETWEEN 148 AND 221 THEN '148-221'
        WHEN LeadTime BETWEEN 222 AND 295 THEN '222-295'
        WHEN LeadTime BETWEEN 296 AND 369 THEN '296-369'
        WHEN LeadTime BETWEEN 370 AND 443 THEN '370-443'
        WHEN LeadTime BETWEEN 444 AND 517 THEN '444-517'
        WHEN LeadTime BETWEEN 518 AND 591 THEN '518-591'
        WHEN LeadTime BETWEEN 592 AND 665 THEN '592-665'
        WHEN LeadTime BETWEEN 666 AND 737 THEN '666-737'
        ELSE 'Unknown'
    END,
    CASE 
        WHEN LeadTime BETWEEN 0 AND 73 THEN 1
        WHEN LeadTime BETWEEN 74 AND 147 THEN 2
        WHEN LeadTime BETWEEN 148 AND 221 THEN 3
        WHEN LeadTime BETWEEN 222 AND 295 THEN 4
        WHEN LeadTime BETWEEN 296 AND 369 THEN 5
        WHEN LeadTime BETWEEN 370 AND 443 THEN 6
        WHEN LeadTime BETWEEN 444 AND 517 THEN 7
        WHEN LeadTime BETWEEN 518 AND 591 THEN 8
        WHEN LeadTime BETWEEN 592 AND 665 THEN 9
        WHEN LeadTime BETWEEN 666 AND 737 THEN 10
        ELSE 'Unknown'
    END
ORDER BY LeadTimeBinList;

--================================================================================
-- 2. Percentage of cancelled bookings by LeadTime threshold (>150 / <150 days)
--================================================================================
SELECT 
    '>150 Days' AS LeadTimeCategory,
    SUM(CASE WHEN LeadTime>150 THEN CAST(Cancelled AS DECIMAL) ELSE 0 END) AS CancelledBookings,
    SUM(CAST(Cancelled AS DECIMAL)) AS TotalCancellations,
    SUM(CASE WHEN LeadTime>150 THEN CAST(Cancelled AS DECIMAL) ELSE 0 END)*100.0/SUM(CAST(Cancelled AS DECIMAL)) AS CancellationPercentage
FROM HotelBookings_replica
UNION ALL
SELECT 
    '<=150 Days' AS LeadTimeCategory,
    SUM(CASE WHEN LeadTime<=150 THEN CAST(Cancelled AS DECIMAL) ELSE 0 END) AS CancelledBookings,
    SUM(CAST(Cancelled AS DECIMAL)) AS TotalCancellations,
    SUM(CASE WHEN LeadTime<=150 THEN CAST(Cancelled AS DECIMAL) ELSE 0 END)*100.0/SUM(CAST(Cancelled AS DECIMAL)) AS CancellationPercentage
FROM HotelBookings_replica;

--================================================================================
-- 3. Pivot table: Booking Count, Avg ADR, Total Revenue by CustomerType
--================================================================================
-- Booking Count Pivot
SELECT 'Booking Count' AS PivotColumn, *
FROM (
    SELECT BookingID, CustomerType
    FROM HotelBookings_replica
) AS BookingCount
PIVOT (
    COUNT(BookingID)
    FOR CustomerType IN ([Transient], [Group], [Contract], [Transient-Party])
) AS BookingCountPivot

UNION ALL

-- Avg ADR Pivot
SELECT 'Avg ADR' AS PivotColumn, *
FROM (
    SELECT AvgDailyRate, CustomerType
    FROM HotelBookings_replica
) AS AvgADR
PIVOT (
    AVG(AvgDailyRate)
    FOR CustomerType IN ([Transient], [Group], [Contract], [Transient-Party])
) AS AvgADRPivot

UNION ALL

-- Total Revenue Pivot
SELECT 'Total Revenue' AS PivotColumn, *
FROM (
    SELECT Revenue, CustomerType
    FROM HotelBookings_replica
) AS RevenueData
PIVOT (
    SUM(Revenue)
    FOR CustomerType IN ([Transient], [Group], [Contract], [Transient-Party])
) AS TotalRevenuePivot;

--================================================================================
-- 4. Z-score calculation for ADR to detect rate outliers
--================================================================================
DECLARE @Mean FLOAT, @STDDEV FLOAT;
SELECT @Mean = AVG(AvgDailyRate) FROM HotelBookings_replica;
SELECT @STDDEV = STDEV(AvgDailyRate) FROM HotelBookings_replica;

WITH ZSCORE AS (
    SELECT
        AvgDailyRate,
        ((AvgDailyRate-@Mean)/@STDDEV) AS [Z_SCORE]
    FROM HotelBookings_replica
)
SELECT *,
    CASE
        WHEN [Z_SCORE]>2 THEN 1
        WHEN [Z_SCORE]<-2 THEN 1
        ELSE 0
    END AS OutlierFlag
FROM ZSCORE;

--================================================================================
-- 5. Overall cancellation percentage
--================================================================================
SELECT 
    COUNT(*) AS Total_Bookings,
    CAST(SUM(CAST(Cancelled AS INT)) AS FLOAT) AS Cancelled_Bookings,
    CAST(SUM(CAST(Cancelled AS INT))*100.0/COUNT(*) AS FLOAT) AS Cancellation_Percentage
FROM HotelBookings_replica;