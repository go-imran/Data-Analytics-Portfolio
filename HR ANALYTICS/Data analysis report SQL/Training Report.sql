-- =========================================
-- View: vw_hr_employee_training_Report
-- Purpose: Generates a detailed Employee Training Report
-- Summary:
-- This report provides a comprehensive overview of all employee training programs,
-- including details like training dates, trainers, outcomes, duration, costs, and effectiveness.
-- Key metrics included:
--   - Training Year, Month, and Quarter for time-based analysis
--   - Completion and Pass flags for each employee
--   - Training count per employee
--   - Training duration in days and calculated hours
--   - Cost per day for each training
--   - Program popularity based on participation count
--   - Trainer effectiveness based on ratio of successful outcomes
-- This view helps HR managers track training participation, performance, cost efficiency,
-- and trainer performance across the organization.
-- =========================================

IF OBJECT_ID('gold.vw_hr_employee_training_Report', 'V') IS NOT NULL
    DROP VIEW gold.vw_hr_employee_training_Report;
GO
CREATE VIEW gold.vw_hr_employee_training_Report AS
SELECT 
	[Employee ID],
	[Training Program Name],
	Trainer,
	[Training Date],
	YEAR([Training Date]) AS [Training Year],
	MONTH([Training Date]) AS [Training Month],
	CASE 
		WHEN MONTH([Training Date]) IN (1,2,3) THEN 'Q1'
		WHEN MONTH([Training Date]) IN (4,5,6) THEN 'Q2'
		WHEN MONTH([Training Date]) IN (7,8,9) THEN 'Q3'
		WHEN MONTH([Training Date]) IN (10,11,12) THEN 'Q4'
	END AS [Training Quarter],
	[Training Outcome],
	CASE 
		WHEN [Training Outcome] IN ('Completed') THEN 1
		ELSE 0
	END AS [Is Completed],
	CASE 
		WHEN [Training Outcome] IN ('Passed') THEN 1
		ELSE 0
	END AS [Is Passed],
	COUNT(*) OVER (PARTITION BY [Employee ID]) AS [Training Count Per Employee],
	[Training Duration Days],
	ROUND([Training Duration Days] * 8, 0) AS [Training Hours],
	[Training Cost],
	CASE 
		WHEN [Training Duration Days] > 0 THEN ROUND(CAST([Training Cost] AS FLOAT) / NULLIF([Training Duration Days],0), 2)
		ELSE 0
	END AS [Cost per Day],
	COUNT(*) OVER(PARTITION BY [Training Program Name]) AS [Program Popularity],
	CAST(
		SUM(CASE 
				WHEN [Training Outcome] IN ('Completed','Passed') THEN 1 
				ELSE 0 
			END) 
		OVER (PARTITION BY Trainer) AS FLOAT
	) 
	/ 
		COUNT(*) OVER (PARTITION BY Trainer) AS [Trainer Effectiveness]	

FROM gold.vw_hr_employee_training;
GO



