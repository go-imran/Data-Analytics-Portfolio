-- ============================================================
-- View: vw_hr_employee_engagement_Report
-- Purpose:
-- Creates a full Employee Engagement Report for HR use.
--
-- Summary:
-- Shows engagement, satisfaction, and work-life balance scores.
-- Tracks whether each score is improving, declining, or stable.
-- Adds improvement scores, trend labels, and risk indicators.
-- Helps HR easily spot employees who may need support early.
-- ============================================================


IF OBJECT_ID('gold.vw_hr_employee_engagement_Report', 'V') IS NOT NULL
    DROP VIEW gold.vw_hr_employee_engagement_Report;
GO
CREATE VIEW gold.vw_hr_employee_engagement_Report AS
SELECT 
	[Employee ID],
	[Employee Name],
	[Survey Date],
	[Survey Year],
	[Survey Month],
	[Engagement Score],
	AVG(CAST([Engagement Score] AS FLOAT)) OVER (PARTITION BY [Employee ID] ORDER BY [Survey Date]  ROWS BETWEEN 2 PRECEDING AND CURRENT ROW) AS [Rolling 3Month Engagement Avg],
	LAG([Engagement Score]) OVER(PARTITION BY [Employee ID] ORDER BY [Survey Date]) AS [Previous Engagement Score],
	[Engagement Score]-LAG([Engagement Score]) OVER(PARTITION BY [Employee ID] ORDER BY [Survey Date]) AS [Engagement Improvement Score],	
	CASE 
		WHEN [Engagement Score] - LAG([Engagement Score]) OVER(PARTITION BY [Employee ID] ORDER BY [Survey Date]) > 0 THEN 'Improving'
		WHEN [Engagement Score] - LAG([Engagement Score]) OVER(PARTITION BY [Employee ID] ORDER BY [Survey Date]) < 0 THEN 'Decling'
		ELSE 'Stable'
	END AS [Engagement Improving Level],	
	CASE 
		WHEN [Engagement Score]<3 THEN 1
		ELSE 0
	END AS [Low Engagement Flag],
	[Satisfaction Score],
	LAG([Satisfaction Score]) OVER (PARTITION BY [Employee ID] ORDER BY [Survey Date]) AS Previous_Satisfaction_Score,   
    ([Satisfaction Score] - LAG([Satisfaction Score]) OVER (PARTITION BY [Employee ID] ORDER BY [Survey Date])) AS [Satisfaction Improvement Score],
	    CASE
        WHEN ([Satisfaction Score] - LAG([Satisfaction Score]) OVER (PARTITION BY [Employee ID] ORDER BY [Survey Date])) > 0 THEN 'Improving'
        WHEN ([Satisfaction Score] - LAG([Satisfaction Score]) OVER (PARTITION BY [Employee ID] ORDER BY [Survey Date])) < 0 THEN 'Declining'
        ELSE 'Stable'
    END AS [Satisfaction Improvement Level],
	[Work-Life Balance Score],
	LAG([Work-Life Balance Score]) OVER (PARTITION BY [Employee ID] ORDER BY [Survey Date]) AS [Previous WLB Score],
    ([Work-Life Balance Score] - LAG([Work-Life Balance Score]) OVER (PARTITION BY [Employee ID] ORDER BY [Survey Date])) AS [WLB Improvement Score],  
    CASE
        WHEN ([Work-Life Balance Score] - LAG([Work-Life Balance Score]) OVER (PARTITION BY [Employee ID] ORDER BY [Survey Date])) > 0 THEN 'Improving'
        WHEN ([Work-Life Balance Score] - LAG([Work-Life Balance Score]) OVER (PARTITION BY [Employee ID] ORDER BY [Survey Date])) < 0 THEN 'Declining'
        ELSE 'Stable'
    END AS [WLB Improvement Level],
	([Engagement Score] * 0.5) + ([Satisfaction Score] * 0.3) + ([Work-Life Balance Score] * 0.2) AS [Composite Engagement Risk Score],
    CASE
        WHEN ([Engagement Score] * 0.5 + [Satisfaction Score] * 0.3 + [Work-Life Balance Score] * 0.2) >= 4 THEN 'Employee is engaged'
        WHEN ([Engagement Score] * 0.5 + [Satisfaction Score] * 0.3 + [Work-Life Balance Score] * 0.2) >= 3 THEN 'Needs monitoring'
        ELSE 'Employee At-Risk'
    END AS [Engagement Risk Level],
	CASE 
		WHEN  
		(CASE
			WHEN ([Engagement Score] * 0.5 + [Satisfaction Score] * 0.3 + [Work-Life Balance Score] * 0.2) >= 4 THEN 'Employee is engaged'
			WHEN ([Engagement Score] * 0.5 + [Satisfaction Score] * 0.3 + [Work-Life Balance Score] * 0.2) >= 3 THEN 'Needs monitoring'
			ELSE 'Employee At-Risk'
			END ) = 'Employee At-Risk' THEN 1
		ELSE 0
	END AS [Risk Employee Flag],
	[Days Since Survey]

FROM gold.vw_hr_employee_engagement

;
GO
