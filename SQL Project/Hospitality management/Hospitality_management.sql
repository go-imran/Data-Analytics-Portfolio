create database Project_Hospitality_management;
use Project_Hospitality_management;

drop table dbo.HotelBookings;


CREATE TABLE HotelBookings (
    BookingID INT PRIMARY KEY,                           -- Unique booking identifier
    Hotel VARCHAR(100),                                  -- Hotel name or code
    BookingDate VARCHAR(100),                                    -- Date when booking was made
    ArrivalDate VARCHAR(100),                                    -- Date of guest arrival
    LeadTime INT,                                        -- Days between booking and arrival
    Nights INT,                                          -- Number of nights stayed
    Guests INT,                                          -- Total number of guests
    DistributionChannel VARCHAR(100),                    -- Booking source/channel (e.g., Online, Travel Agent)
    CustomerType VARCHAR(50),                            -- Customer classification (e.g., Transient, Group)
    Country VARCHAR(100),                                -- Guest's country of origin
    DepositType VARCHAR(50),                             -- Type of deposit (e.g., No Deposit, Refundable)
    AvgDailyRate DECIMAL(10, 2),                         -- Average rate per night
    Status VARCHAR(50),                                  -- Booking status (e.g., Confirmed, Checked-Out)
    StatusUpdate VARCHAR(100),                                   -- Last status update date
    Cancelled BIT,                                       -- 1 = Cancelled, 0 = Not Cancelled
    Revenue varchar(50),                              -- Actual earned revenue
    RevenueLoss varchar(50)                           -- Lost revenue from cancellations
);

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

select * from HotelBookings;



CREATE TABLE HotelBookings_replica (
    BookingID INT PRIMARY KEY,                           -- Unique booking identifier
    Hotel VARCHAR(100),                                  -- Hotel name or code
    BookingDate VARCHAR(100),                                    -- Date when booking was made
    ArrivalDate VARCHAR(100),                                    -- Date of guest arrival
    LeadTime INT,                                        -- Days between booking and arrival
    Nights INT,                                          -- Number of nights stayed
    Guests INT,                                          -- Total number of guests
    DistributionChannel VARCHAR(100),                    -- Booking source/channel (e.g., Online, Travel Agent)
    CustomerType VARCHAR(50),                            -- Customer classification (e.g., Transient, Group)
    Country VARCHAR(100),                                -- Guest's country of origin
    DepositType VARCHAR(50),                             -- Type of deposit (e.g., No Deposit, Refundable)
    AvgDailyRate DECIMAL(10, 2),                         -- Average rate per night
    Status VARCHAR(50),                                  -- Booking status (e.g., Confirmed, Checked-Out)
    StatusUpdate VARCHAR(100),                                   -- Last status update date
    Cancelled BIT,                                       -- 1 = Cancelled, 0 = Not Cancelled
    Revenue varchar(50),                              -- Actual earned revenue
    RevenueLoss varchar(50)                           -- Lost revenue from cancellations
);

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


select * from HotelBookings_replica;

EXEC sp_help HotelBookings_replica;

alter table HotelBookings_replica
add BookingDate_new date;

alter table HotelBookings_replica
add StatusUpdate_new date;

update HotelBookings_replica
set StatusUpdate_new=TRY_CONVERT(date,StatusUpdate,103)
where StatusUpdate_new is null;

alter table HotelBookings_replica
drop column StatusUpdate;

SELECT * from HotelBookings_replica;

select ArrivalDate, TRY_CONVERT(date,ArrivalDate,103)
from HotelBookings_replica;

alter table HotelBookings_replica
add ArrivalDate_new date;

update HotelBookings_replica
set ArrivalDate_new=TRY_CONVERT(date,ArrivalDate,103)
where ArrivalDate_new is null;

EXEC sp_rename 'HotelBookings_replica.ArrivalDate_new', 'ArrivalDate', 'COLUMN';

EXEC sp_rename 'HotelBookings_replica.StatusUpdate_new', 'StatusUpdate', 'COLUMN';

exec sp_help HotelBookings_replica;

select Revenue, TRY_CONVERT(decimal(10,2),Revenue)
from HotelBookings_replica;

select RevenueLoss, TRY_CONVERT(decimal(10,2),RevenueLoss)
from HotelBookings_replica;

alter table HotelBookings_replica
add RevenueLoss_new decimal(10,2);

update HotelBookings_replica
set RevenueLoss_new=TRY_CONVERT(decimal(10,2),RevenueLoss)
where RevenueLoss_new is null;

alter table HotelBookings_replica
drop column RevenueLoss;

EXEC sp_rename 'HotelBookings_replica.Revenue_new', 'Revenue', 'COLUMN';
--data cleaning part end--

--Customer Insights (Behavior, Segmentation, Loyalty)--

--Which customer type generates the highest average revenue per booking?

select CustomerType,avg(Revenue) as avg_revenue
from HotelBookings_replica
GROUP BY CustomerType
ORDER BY avg_revenue DESC;

/*How does the average number of nights differ across customer types 
(e.g., Transient vs. Group)?*/

select CustomerType, AVG(Nights) as avg_nights
from HotelBookings_replica
group by CustomerType
order by avg_nights asc;

/*Which countries have the highest average daily rate (ADR)?*/
select top(10) Country, avg(AvgDailyRate) as avg_of_avg_daily_Rate
from HotelBookings_replica
group by Country
order by avg_of_avg_daily_Rate desc;

/*Identify the top 10 countries with the highest booking volume. 
How does their average cancellation rate compare?*/

CREATE NONCLUSTERED INDEX IX_Country_Cancelled  
ON HotelBookings_replica (Country, Cancelled);

drop index IX_Country_Cancelled on HotelBookings_replica;

declare @total int
select @total= count(Cancelled) from HotelBookings_replica where Cancelled=1;

with tab1 as(
select Country,(CAST(COUNT(Cancelled) AS decimal) / @total)*100 as booking_percentages
from HotelBookings_replica
where Cancelled=1
group by Country
),

tab2 as (
select  Country, count(BookingID) as Booking_count
from HotelBookings_replica
group by Country
)

select top(10) tab2.Country,tab2.Booking_count,isnull(tab1.booking_percentages,0) as cancellation_Rate
from tab2 
left join tab1 on tab1.Country=tab2.Country
order by tab2.Booking_count desc;

--Which customer type has the highest cancellation rate and average lead time?

declare @total int
select @total= count(Cancelled) from HotelBookings_replica where Cancelled=1;

select CustomerType,(CAST(COUNT(Cancelled) AS decimal) / @total)*100 as cancellation_percentages
from HotelBookings_replica
where Cancelled=1
group by CustomerType
order by cancellation_percentages desc
;



select CustomerType,avg(LeadTime) as avg_lead_time
from HotelBookings_replica
where Cancelled=1
group by CustomerType
order by avg_lead_time desc
;


use Project_Hospitality_management;

-- What is the median lead time for each customer type?

create nonclustered index ix_customerType_leadTime
on HotelBookings_replica(CustomerType,LeadTime);

drop index ix_customerType_leadTime on HotelBookings_replica;

select distinct CustomerType,
PERCENTILE_CONT(0.5) within group (order by LeadTime asc)
over(partition by CustomerType) as Median
from HotelBookings_replica;

/*Cluster countries by similar booking behaviors: number of guests, lead time, 
and ADR (k-means possible after SQL pre-aggregation).*/

select Country,avg_guest,
PERCENTILE_CONT(0.25) within group(order by avg_guest)
over() 
from (
select Country,
avg(Guests) as avg_guest,
avg(LeadTime) as avg_leadTime,
avg(AvgDailyRate) as avg_of_avg_daiyRate
from HotelBookings_replica
group by Country) tab1;

-- Calculate the percentage of bookings with more than 3 guests and analyze their revenue impact.

create nonclustered index ix_guest
on HotelBookings_replica(Guests);

select 
(count(case when Guests>3 then BookingID else null end)/cast(count(*) as decimal))*100 as Booking_percentages,
sum(case when Guests>3 then Revenue else 0 end) as total_Rev,
sum(case when Guests>3 then RevenueLoss else 0 end) as total_Rev_loss
from HotelBookings_replica;

-- Revenue Management-- 
-- Calculate total revenue, revenue loss, and net revenue monthly.

create nonclustered index ix_ArrivalDate
on HotelBookings_replica(ArrivalDate)
include(Revenue);

create nonclustered index ix_StatusUpdate
on HotelBookings_replica(StatusUpdate)
include(RevenueLoss);

drop index ix_StatusUpdate on HotelBookings_replica;

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
LEFT JOIN tab2 
    ON tab1.Month_number = tab2.Month_number
ORDER BY tab1.Month_number ASC;

/*This is a classic example for creating temporary table*/
-- tab3 as temp table
SELECT MONTH(ArrivalDate) AS Month_number, SUM(Revenue) AS Total_Rev
INTO #tab3
FROM HotelBookings_replica
GROUP BY MONTH(ArrivalDate);

-- tab4 as temp table
SELECT MONTH(StatusUpdate) AS Month_number, SUM(RevenueLoss) AS Total_RevLoss
INTO #tab4
FROM HotelBookings_replica
GROUP BY MONTH(StatusUpdate);

-- Optional: Add index on temp tables
CREATE NONCLUSTERED INDEX ix_month_tab1 ON #tab3(Month_number);
CREATE NONCLUSTERED INDEX ix_month_tab2 ON #tab4(Month_number);

-- Final join query
SELECT 
    t1.Month_number,
    t1.Total_Rev,
    t2.Total_RevLoss
FROM #tab3 t1
LEFT JOIN #tab4 t2 ON t1.Month_number = t2.Month_number
ORDER BY t1.Month_number;

select * from #tab1 t
order by t.Month_number;

-- What is the average revenue loss due to cancellations per month?

select month(StatusUpdate) as Month_Number,
avg(RevenueLoss) as AvgRevLoss
from HotelBookings_replica
where Cancelled = 1
group by month(StatusUpdate)
order by month(StatusUpdate) asc;

--Which distribution channel is associated with the highest revenue loss rate?

select DistributionChannel,abs(SUM(RevenueLoss)) as Total_revLoss
from HotelBookings_replica
group by DistributionChannel
order by Total_revLoss desc;

--Identify the top 10 days with the highest net revenue.

select top(10) ArrivalDate,SUM(Net_Rev) as actual_netRev
from(
select ArrivalDate,(Revenue+RevenueLoss) as Net_Rev
from HotelBookings_replica
) tab1
group by ArrivalDate
order by actual_netRev desc;

-- Which country brings in the highest revenue per night on average?

select Country, (SUM(Revenue)/SUM(Nights)) as RevPerNights
from HotelBookings_replica
where Nights>0
group by Country
order by RevPerNights desc;

/*Calculate the coefficient of variation (standard deviation ÷ mean) of ADR 
across months to assess rate volatility.*/


select month(ArrivalDate) as MonthNumber,
(STDEVP(AvgDailyRate)*1.0/AVG(AvgDailyRate)) as CoeefitientVarience
from HotelBookings_replica
where AvgDailyRate>0
group by month(ArrivalDate)
order by month(ArrivalDate) asc;

-- Which customer type shows the greatest variability in ADR?

select CustomerType,STDEVP(AvgDailyRate) as StandardDeviations
from HotelBookings_replica
group by CustomerType
order by StandardDeviations desc;

-- Compute revenue per guest per booking and analyze trends across seasons.
with tab1 as (
select MONTH(ArrivalDate) as Month_Number, (SUM(Revenue)/SUM(Guests)) as RevPerGuest
from HotelBookings_replica
where Guests>0
group by MONTH(ArrivalDate)
),

tab2 as (
select Month_Number,
case
    WHEN Month_Number BETWEEN 3 AND 5 THEN 'Spring'
    WHEN Month_Number BETWEEN 6 AND 8 THEN 'Summer'
    WHEN Month_Number BETWEEN 9 AND 11 THEN 'Autumn'
	else 'Winter'
	end as Seasons
from tab1
)
select tab2.Month_Number,tab2.Seasons,tab1.RevPerGuest
from tab2 
left join tab1 on tab2.Month_Number=tab1.Month_Number
order by tab2.Month_Number; 

-- Compare avg ADR before and after cancellations by customer type.
with cte as (
select CustomerType,avg(AvgDailyRate) as Total_AVD_before_cancell
from HotelBookings_replica
where Cancelled=0
GROUP BY CustomerType),
cte2 as (
select CustomerType,avg(AvgDailyRate) as Total_AVD_after_cancell
from HotelBookings_replica
where Cancelled=1
GROUP BY CustomerType)

select c2.CustomerType, c.Total_AVD_before_cancell,c2.Total_AVD_after_cancell
from cte2 c2 
full outer join cte c on c.CustomerType=c2.CustomerType;

-- Which day of the week has the highest average arrival count?

with cte as(
select DATENAME(WEEKDAY, ArrivalDate) AS Day_of_week,
ArrivalDate,
COUNT(*) AS Arrival_count
FROM HotelBookings_replica
where Cancelled = 0
group by DATENAME(WEEKDAY, ArrivalDate),ArrivalDate)

select Day_of_week,AVG(Arrival_count) as Avg_count
from cte
group by Day_of_week
order by Avg_count desc;



select DATENAME(WEEKDAY,ArrivalDate) as Days_of_week, 
COUNT(ArrivalDate) as Arrival_count into temp_tab
from HotelBookings_replica
group by DATENAME(WEEKDAY,ArrivalDate);

declare @Totalcount decimal(10,2);
select @Totalcount=SUM(Arrival_count)from temp_tab;
select Days_of_week,(Arrival_count*100/@Totalcount)
from temp_tab;

-- What is the average length of stay per customer type?
select CustomerType,avg(Nights) as avg_Stay
from HotelBookings_replica
group by CustomerType;

-- Identify overbooked days (bookings > available capacity — assuming a capacity constraint).
-- lets assume, In this hotel it has maximaum capacity of 350 bookings.
select ArrivalDate,TotalBooking,
case
	when TotalBooking>350 then 'Overbooked'
	else 'RegularBooking'
	end as 'BookingCapacity'
from (
select ArrivalDate, COUNT(distinct BookingID) as TotalBooking
from HotelBookings_replica
group by ArrivalDate
) hotel;

-- Find the longest lead times for each distributionchannel?

select DistributionChannel,
MAX(LeadTime) as LongestLeadTime
from HotelBookings_replica
group by DistributionChannel
order by LongestLeadTime desc;

-- Determine the busiest months by total guest count.

select top(3) MONTH(ArrivalDate) as MonthNumber,
sum(Guests) as GuestsNumber
from HotelBookings_replica
group by MONTH(ArrivalDate)
order by GuestsNumber desc
;

-- What is the percentage of bookings with 1-6 night stays vs. long stays (7+ nights)?

DECLARE @ShortStays DECIMAL(10,2);
DECLARE @LongStays DECIMAL(10,2);
DECLARE @TotalStays DECIMAL(10,2);

SELECT @ShortStays = COUNT(*)
FROM HotelBookings_replica
WHERE Nights>0 and Nights<7 ;

SELECT @LongStays = COUNT(*)
FROM HotelBookings_replica
WHERE Nights >= 7;

SELECT @TotalStays = COUNT(*)
FROM HotelBookings_replica
WHERE Nights IS NOT NULL;

SELECT 
  CAST((@ShortStays * 100.0) / @TotalStays AS DECIMAL(10,2)) AS ShortStays_Percentage,
  CAST((@LongStays * 100.0) / @TotalStays AS DECIMAL(10,2)) AS LongStays_Percentage;

-- Analyze booking peaks and identify if lead times are sufficient for operational preparation.

select MONTH(ArrivalDate) as MonthNumber,AVG(LeadTime) as AvgLeadTime,
count(BookingID) as NumOfBookings
from HotelBookings_replica
group by MONTH(ArrivalDate)
order by NumOfBookings desc;

/* Calculate standard deviation of guest count per day. 
Identify high-variance days (operational risk).*/

with GuestCount as(
select ArrivalDate, sum(Guests) as TotalGuests
from HotelBookings_replica
group by ArrivalDate
),
GuestStdv as (
select AVG(TotalGuests) as MeanGuest,
STDEV(TotalGuests) as TotalGueststdv
from GuestCount),

ZScore as (
select g.ArrivalDate, g.TotalGuests,
round(((g.TotalGuests- s.MeanGuest)/s.TotalGueststdv),3) as Zscore
from GuestCount g
cross join GuestStdv s
)
select z.ArrivalDate,z.TotalGuests,z.Zscore,
case
	when z.Zscore>2 then 'Unusually high guest'
	when z.Zscore<-2 then 'Unusually low guest'
	else 'Normal'
	end as 'GuestQuantity'
from ZScore z
order by z.Zscore desc;

select YEAR(ArrivalDate),
MONTH(ArrivalDate),
SUM(Revenue) over(ORDER BY YEAR(ArrivalDate), MONTH(ArrivalDate))
from HotelBookings_replica
group by YEAR(ArrivalDate),MONTH(ArrivalDate)
;
-- cumalitive revenue per month
SELECT 
  YEAR(ArrivalDate) AS ArrivalYear,
  MONTH(ArrivalDate) AS ArrivalMonth,
  SUM(Revenue) AS MonthlyRevenue,
  SUM(SUM(Revenue)) OVER (
    ORDER BY YEAR(ArrivalDate), MONTH(ArrivalDate)
    ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
  ) AS CumulativeRevenue
FROM HotelBookings_replica
GROUP BY YEAR(ArrivalDate), MONTH(ArrivalDate)
ORDER BY YEAR(ArrivalDate), MONTH(ArrivalDate);

-- Which month had the highest average number of guests per booking?

with Guest as(
select MONTH(ArrivalDate) as MonthNumber,
SUM(Guests) as TotalGuest
from HotelBookings_replica
group by MONTH(ArrivalDate)),

Booking as (
select MONTH(ArrivalDate) as MonthNumber,
count(BookingID) as Totalbookings
from HotelBookings_replica 
group by MONTH(ArrivalDate)
)

select top(2) g.MonthNumber, cast((g.TotalGuest/b.Totalbookings) as decimal(10,2)) as AvgGuests
from Guest g
join Booking b on g.MonthNumber=b.MonthNumber
order by AvgGuests desc;

-- Calculate month-over-month growth in net revenue.

select YearValue,MonthNumber,TotalRev,LagRev,
cast(((TotalRev-LagRev)/LagRev) as decimal(10,2)) as MonthOverMonth
from(
select year(ArrivalDate) as YearValue, MONTH(ArrivalDate) as MonthNumber,
SUM(Revenue) as TotalRev,
LAG(SUM(Revenue)) over (partition by year(ArrivalDate) order by MONTH(ArrivalDate)) as LagRev
from HotelBookings_replica
group by year(ArrivalDate),MONTH(ArrivalDate)) as LagRevByMonth;

-- What is the 3-month moving average of ADR ?

select YEAR(ArrivalDate) as YearValue,
MONTH(ArrivalDate) as MonthNumber,
AVG(AvgDailyRate) as AvgADR,
ROW_NUMBER() over(
partition by YEAR(ArrivalDate) order by YEAR(ArrivalDate),MONTH(ArrivalDate),AVG(AvgDailyRate)) as RowNum,

CASE
	when ROW_NUMBER() over(
		 partition by YEAR(ArrivalDate) order by YEAR(ArrivalDate),MONTH(ArrivalDate),AVG(AvgDailyRate))>=3
	then  
		 AVG(AVG(AvgDailyRate)) over (
		 PARTITION BY YEAR(ArrivalDate)
		 ORDER BY MONTH(ArrivalDate)
		 ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
			  )	
else null 
end as 'MovingAvg'
from HotelBookings_replica
group by YEAR(ArrivalDate),MONTH(ArrivalDate)
;

-- Predict next month's (sept 2017) revenue using linear trend (past n=15 months as input).

WITH BaseTable as(
select year(ArrivalDate) as YearValue,
	   MONTH(ArrivalDate) as MonthNumber,
	   ROW_NUMBER() over(order by year(ArrivalDate) ,MONTH(ArrivalDate)) as MonthIndex,
	   AVG(Revenue) as AvgRevnue,
	   (ROW_NUMBER() over(order by year(ArrivalDate) ,MONTH(ArrivalDate))*AVG(Revenue)) as XY,
	   POWER(ROW_NUMBER() OVER (ORDER BY YEAR(ArrivalDate), MONTH(ArrivalDate)), 2) AS X_MultiplyBy_X
from HotelBookings_replica
group by year(ArrivalDate) ,MONTH(ArrivalDate)
),

TotalXY as(
select  SUM(XY) as SumXY, SUM(X_MultiplyBy_X) as SumX_MultiplyBy_X,SUM(MonthIndex) as SumX,
        (SUM(MonthIndex) * SUM(MonthIndex)) as SumX_MultiplyBy_SumX, SUM(AvgRevnue) AS SumY
from BaseTable),

calculationTable as (
select b.YearValue,b.MonthNumber, b.MonthIndex,b.AvgRevnue,b.XY,b.X_MultiplyBy_X, t.SumXY,
	   t.SumX_MultiplyBy_X, t.SumX,t.SumX_MultiplyBy_SumX, t.SumY
from BaseTable b
cross join TotalXY t),

Find_ab as(
select (((15*c.SumXY)-(c.SumX*c.SumY))/((15*c.SumX_MultiplyBy_X)-(c.SumX_MultiplyBy_SumX))) as a,
       ((c.SumY-(((15*c.SumXY)-(c.SumX*c.SumY))/((15*c.SumX_MultiplyBy_X)-(c.SumX_MultiplyBy_SumX))*c.SumX))/15) as b
from calculationTable c)

select  distinct (a*16+b) as ExpectedAvgRevForSept2017
from Find_ab;

-- Which months show consistent peaks in bookings over the last 3 years (seasonality)?

WITH MonthlyData AS (
  SELECT 
    MONTH(ArrivalDate) AS MonthNumber,
    COUNT(CASE WHEN YEAR(ArrivalDate) = 2015 THEN BookingID END) AS Bookings_2015,
    COUNT(CASE WHEN YEAR(ArrivalDate) = 2016 THEN BookingID END) AS Bookings_2016,
    COUNT(CASE WHEN YEAR(ArrivalDate) = 2017 THEN BookingID END) AS Bookings_2017
  FROM HotelBookings_replica
  GROUP BY MONTH(ArrivalDate)
),
FULLTABLE AS (
SELECT *, 
  (SELECT COUNT(BookingID)/36.0
   FROM HotelBookings_replica) as AvgBookingFor3years
FROM MonthlyData
)

SELECT 
   F.MonthNumber,
   CASE WHEN F.Bookings_2015=0 THEN 0 ELSE CAST(((F.Bookings_2015-F.AvgBookingFor3years)/F.AvgBookingFor3years)*100 AS DECIMAL(10,2)) END AS Seasonality_peak_2015,
   CASE WHEN F.Bookings_2016=0 THEN 0 ELSE CAST(((F.Bookings_2016-F.AvgBookingFor3years)/F.AvgBookingFor3years)*100 AS DECIMAL(10,2)) END AS Seasonality_peak_2016,
   CASE WHEN F.Bookings_2017=0 THEN 0 ELSE CAST(((F.Bookings_2017-F.AvgBookingFor3years)/F.AvgBookingFor3years)*100 AS DECIMAL(10,2))  END AS Seasonality_peak_2017
FROM FULLTABLE F
ORDER BY F.MonthNumber;

-- Compare revenue EXPECTED vs. actual .

SELECT 
  MONTH(ArrivalDate) AS MonthNumber,
  (ABS(SUM(RevenueLoss))+SUM(Revenue)) AS ExpectedRevenue,
  SUM(Revenue) AS ActualRevenue,
  ABS(SUM(RevenueLoss)) AS LostRevenue,
  Cast((SUM(Revenue)/(ABS(SUM(RevenueLoss))+SUM(Revenue)))*100 AS DECIMAL(10,2)) AS Revenue_Percentage
FROM HotelBookings_replica
GROUP BY MONTH(ArrivalDate)
ORDER BY MONTH(ArrivalDate);

-- Estimate daily booking trend over time using 7-day rolling averages.

SELECT
   YEAR(ArrivalDate) AS ArrivalYear,
   ArrivalDate,
   COUNT(BookingID) AS Daily_Booking,
   ROW_NUMBER() OVER(ORDER BY ArrivalDate) AS RowValue,
   CASE
      WHEN (ROW_NUMBER() OVER(ORDER BY ArrivalDate))>=7 THEN AVG(COUNT(BookingID)) OVER(ORDER BY ArrivalDate ROWS BETWEEN 6 PRECEDING AND CURRENT ROW) 
	  ELSE NULL END AS '7-day rolling averages'
FROM HotelBookings_replica
GROUP BY YEAR(ArrivalDate),ArrivalDate
;

-- Find anomalies in ADR (e.g., days with >2 SD above/below monthly mean).

DECLARE @SDForADR DECIMAL(10,2)
DECLARE @MEANForADR DECIMAL(10,2)

SELECT @SDForADR=STDEV(AvgDailyRate) FROM HotelBookings_replica;
SELECT @MEANForADR=AVG(AvgDailyRate) FROM HotelBookings_replica;

SELECT AvgDailyRate,
  CASE
	WHEN AvgDailyRate>(@MEANForADR+2*@SDForADR) OR AvgDailyRate<(@MEANForADR-2*@SDForADR) THEN 'OUTLIER'
	ELSE 'NORMAL'
	END AS 'ANOMALIES'
FROM HotelBookings_replica;

/*Which customer type shows the most predictable booking pattern 
(lowest ADR standard deviation AND CV)?*/

SELECT
   CustomerType, 
   AVG(AvgDailyRate) AS ADR,
   CAST(STDEV(AvgDailyRate) AS DECIMAL(10,2)) AS STD_ADR, 
   CAST(STDEV(AvgDailyRate) / NULLIF(AVG(AvgDailyRate), 0) AS DECIMAL(10,2)) AS CV_ADR
FROM HotelBookings_replica
GROUP BY CustomerType;

/*  ( VIEW, INDEX VIEW)
CREATE VIEW TEST1 WITH SCHEMABINDING AS(
SELECT
   BookingID,
   Country,
   AvgDailyRate
FROM dbo.HotelBookings_replica);

CREATE UNIQUE CLUSTERED INDEX IX_TEST1
ON dbo.TEST1(BookingID);

SELECT *
FROM dbo.TEST1;

CREATE VIEW TEST2 AS (
SELECT DistributionChannel, AvgDailyRate
FROM HotelBookings_replica
);

CREATE VIEW TEST3 WITH SCHEMABINDING AS (
SELECT BookingID,DistributionChannel,
Revenue
FROM dbo.HotelBookings_replica

);*/

-- Compare ADR and revenue between hotels if multiple hotels are present.

SELECT
    Hotel,
	AVG(AvgDailyRate) AVGADR,
    ROUND(SUM(Revenue)/1000000.0,2) TotalREV -- Converted the sum into MILLIONS
FROM HotelBookings_replica
GROUP BY Hotel;

-- Which distribution channel yields the highest revenue per guest?


SELECT 
	DistributionChannel,
	SUM(Revenue)/COUNT(*) RevPerGuests,
	MAX(SUM(Revenue)*1.0/COUNT(*)) OVER() HighestREV
FROM HotelBookings_replica
GROUP BY DistributionChannel;

--Compare cancellation PERCENTAGES across customer types and countries.

DECLARE @TotalCancelled decimal(10,2)
SELECT @TotalCancelled = SUM(CAST(Cancelled AS decimal)) FROM HotelBookings_replica;

SELECT 
	CustomerType,
	ISNULL(Country,'UNKNOWN') COUNTRY,
	SUM(CAST(Cancelled AS DECIMAL(10,2))) TotalCancellation,
	SUM(CAST(Cancelled AS DECIMAL(10,2)))*100/@TotalCancelled TotalCancellationPercentages
FROM HotelBookings_replica
GROUP BY CustomerType, Country
HAVING SUM(CAST(Cancelled AS DECIMAL(10,2))) <> 0
ORDER BY CustomerType
;

-- How does the average lead time of bookings differ between local and international customers?
-- Lets assume UNITED KINGDOM is local


SELECT
	AVG(CASE 
		WHEN Country='United Kingdom' THEN LeadTime ELSE NULL END) LocalAVGLeadTime,
	AVG(CASE 
		WHEN Country<>'United Kingdom' THEN LeadTime ELSE NULL END) InternationalAVGLeadTime
FROM HotelBookings_replica
;

--Determine market share by country (number of bookings).

SELECT 
	ISNULL(Country,'UNKNOWN') COUNTRY,
	COUNT(BookingID)*100.0/(SELECT COUNT(*) FROM HotelBookings_replica WHERE Cancelled<>1) BookingPercentages
FROM HotelBookings_replica
WHERE Cancelled<>1
GROUP BY Country
ORDER BY COUNT(BookingID)*100.0/(SELECT COUNT(*) FROM HotelBookings_replica WHERE Cancelled<>1) DESC;

--Compare top 5 customer segments by net profit per booking.

SELECT
	CustomerType,
	SUM(Revenue) TotalREV,
	ABS(SUM(RevenueLoss)) TotalREVLoss,
	SUM(Revenue)-ABS(SUM(RevenueLoss)) NetProfit,
	CAST(SUM(Revenue) - ABS(SUM(RevenueLoss)) AS FLOAT) / NULLIF(COUNT(*), 0) AS ProfitPerBooking
FROM HotelBookings_replica
GROUP BY CustomerType
ORDER BY SUM(Revenue)-ABS(SUM(RevenueLoss)) DESC;

--What is the correlation between lead time and cancellation rate?

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
    WHEN LeadTime BETWEEN 0 AND 73 THEN '0–73'
    WHEN LeadTime BETWEEN 74 AND 147 THEN '74–147'
    WHEN LeadTime BETWEEN 148 AND 221 THEN '148–221'
    WHEN LeadTime BETWEEN 222 AND 295 THEN '222–295'
    WHEN LeadTime BETWEEN 296 AND 369 THEN '296–369'
    WHEN LeadTime BETWEEN 370 AND 443 THEN '370–443'
    WHEN LeadTime BETWEEN 444 AND 517 THEN '444–517'
    WHEN LeadTime BETWEEN 518 AND 591 THEN '518–591'
    WHEN LeadTime BETWEEN 592 AND 665 THEN '592–665'
    WHEN LeadTime BETWEEN 666 AND 737 THEN '666–737'
    ELSE 'Unknown'
  END AS LeadTimeBin,
  COUNT(*) AS TotalBookings,
  SUM(CAST(Cancelled AS INT)) AS Cancellations,
  ROUND(SUM(CAST(Cancelled AS FLOAT))*100.0 / COUNT(*), 2) AS CancellationRate
FROM HotelBookings_replica
GROUP BY 
  CASE 
    WHEN LeadTime BETWEEN 0 AND 73 THEN '0–73'
    WHEN LeadTime BETWEEN 74 AND 147 THEN '74–147'
    WHEN LeadTime BETWEEN 148 AND 221 THEN '148–221'
    WHEN LeadTime BETWEEN 222 AND 295 THEN '222–295'
    WHEN LeadTime BETWEEN 296 AND 369 THEN '296–369'
    WHEN LeadTime BETWEEN 370 AND 443 THEN '370–443'
    WHEN LeadTime BETWEEN 444 AND 517 THEN '444–517'
    WHEN LeadTime BETWEEN 518 AND 591 THEN '518–591'
    WHEN LeadTime BETWEEN 592 AND 665 THEN '592–665'
    WHEN LeadTime BETWEEN 666 AND 737 THEN '666–737'
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

-- What percentage of cancelled bookings came from customers with '>150 & <150' day lead time?

SELECT 
	SUM(CASE
	   WHEN LeadTime>150 THEN cast(Cancelled as decimal) ELSE 0    
	   END) AS '>150 & <150',
	SUM(cast(Cancelled as decimal)) TotalCancellation,
	SUM(CASE
	   WHEN LeadTime>150 THEN cast(Cancelled as decimal) ELSE 0 END)*100.0/SUM(cast(Cancelled as decimal)) Cancellationpercentages
FROM HotelBookings
UNION ALL
SELECT 
	SUM(CASE
	   WHEN LeadTime<150 THEN cast(Cancelled as decimal) ELSE 0    
	   END) AS '>150 & <150',
	SUM(cast(Cancelled as decimal)) TotalCancellation,
	SUM(CASE
	   WHEN LeadTime<150 THEN cast(Cancelled as decimal) ELSE 0 END)*100.0/SUM(cast(Cancelled as decimal)) Cancellationpercentages
FROM HotelBookings;

-- create pivot table for CustomerType for various Aggregrate calculations
SELECT 
    'Booking Count' AS PivotColumn,
    *
FROM (
    SELECT
        BookingID,
        CustomerType
    FROM HotelBookings_replica
) AS BookingCount
PIVOT (
    COUNT(BookingID)
    FOR CustomerType IN ([Transient], [Group], [Contract], [Transient-Party])
) AS BookingCountPivot

UNION ALL

SELECT 
    'Avg ADR' AS PivotColumn,
    *
FROM (
    SELECT
        AvgDailyRate,
        CustomerType
    FROM HotelBookings_replica
) AS AvgADR
PIVOT (
    AVG(AvgDailyRate)
    FOR CustomerType IN ([Transient], [Group], [Contract], [Transient-Party])
) AS AvgADRPivot

UNION ALL
SELECT 
    'Total Revenue' AS PivotColumn,
    *
FROM (
    SELECT
        Revenue,
        CustomerType
    FROM HotelBookings_replica
) AS AvgADR
PIVOT (
    SUM(Revenue)
    FOR CustomerType IN ([Transient], [Group], [Contract], [Transient-Party])
) AS TotalRevenuePivot;

-- Calculate z-scores for ADR to detect rate outliers.

DECLARE @Mean FLOAT 
SELECT @Mean =AVG(AvgDailyRate) FROM HotelBookings_replica;
DECLARE @STDDEV FLOAT
SELECT @STDDEV = STDEV(AvgDailyRate) FROM HotelBookings_replica;

WITH ZSCORE AS (
SELECT
	AvgDailyRate ,
	((AvgDailyRate-@Mean)/@STDDEV) AS [Z-SCORE]
	
FROM HotelBookings_replica
)

SELECT 
	*,
	CASE
		WHEN [Z-SCORE]>2 THEN 1
		WHEN [Z-SCORE]<-2 THEN 1
		ELSE 0
	END AS FLAG
FROM ZSCORE;


-- Overall cancellation percentage
SELECT 
    COUNT(*) AS Total_Bookings,
    CAST(SUM(CAST([Cancelled] AS INT)) AS FLOAT) AS Cancelled_Bookings,
    CAST(SUM(CAST([Cancelled] AS INT)) * 100.0 / COUNT(*) AS FLOAT) AS Cancellation_Percentage
FROM HotelBookings_replica;


select * from HotelBookings_replica;















