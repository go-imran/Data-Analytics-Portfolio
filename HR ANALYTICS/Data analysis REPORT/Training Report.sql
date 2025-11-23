
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

SELECT * FROM gold.vw_hr_employee_training_Report;

