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

SELECT 
	[Employee ID],
	[Employee Name],
	[Survey Date],
	[Survey Year],
	[Survey Month],
	[Engagement Score],
	LAG([Engagement Score]) OVER(PARTITION BY [Employee ID] ORDER BY [Survey Date]) AS [Previous Engagement Score],
	[Engagement Score]-LAG([Engagement Score]) OVER(PARTITION BY [Employee ID] ORDER BY [Survey Date]) AS [Engagement Improvement Score],	
	CASE 
		WHEN [Engagement Score] - LAG([Engagement Score]) OVER(PARTITION BY [Employee ID] ORDER BY [Survey Date]) > 0 THEN 'Improving'
		WHEN [Engagement Score] - LAG([Engagement Score]) OVER(PARTITION BY [Employee ID] ORDER BY [Survey Date]) < 0 THEN 'Decling'
		ELSE 'Stable'
	END AS [Engagement Improving Level],
	[Engagement Level],	
	[Satisfaction Score],
	LAG([Satisfaction Score]) OVER (PARTITION BY [Employee ID] ORDER BY [Survey Date]) AS Previous_Satisfaction_Score,   
    ([Satisfaction Score] - LAG([Satisfaction Score]) OVER (PARTITION BY [Employee ID] ORDER BY [Survey Date])) AS [Satisfaction Improvement Score],
	    CASE
        WHEN ([Satisfaction Score] - LAG([Satisfaction Score]) OVER (PARTITION BY [Employee ID] ORDER BY [Survey Date])) > 0 THEN 'Improving'
        WHEN ([Satisfaction Score] - LAG([Satisfaction Score]) OVER (PARTITION BY [Employee ID] ORDER BY [Survey Date])) < 0 THEN 'Declining'
        ELSE 'Stable'
    END AS [Satisfaction Improvement Level],
	[Satisfaction Level],
	[Work-Life Balance Score],
	[Work-Life Balance Level],
	[Days Since Survey]

FROM gold.vw_hr_employee_engagement
ORDER BY [Employee ID],[Survey Date]
;


--SELECT * FROM gold.vw_hr_employee_engagement;

