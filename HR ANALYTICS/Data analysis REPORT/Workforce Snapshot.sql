-- ============================================================
-- View: vw_employee_Data_Report
-- Purpose:
-- Creates a consolidated Employee Master Report for HR.
--
-- Summary:
-- Includes employee demographics, tenure, performance, seniority,
-- and multiple risk scoring models (tenure risk, age risk, performance risk).
-- Generates Employee Lifetime Value, Seniority Level, and
-- an overall Retention Risk Category.
--
-- HR Use:
-- Helps identify high-value employees, detect retention risks early,
-- and support data-driven workforce planning.
-- ============================================================

IF OBJECT_ID('gold.vw_employee_Data_Report', 'V') IS NOT NULL
    DROP VIEW gold.vw_employee_Data_Report;
GO
CREATE VIEW gold.vw_employee_Data_Report AS

SELECT 
	EmpID AS [EmployeeID],
	[Full Name],
	StartDate,
	ExitDate,
	[Job Title],
	[Department Type],
	[Gender Code],
	[Race Description],
	ISNULL(DATEDIFF(DAY,StartDate,ExitDate),0) AS [Tenure_Days],
	CASE
		WHEN ISNULL(DATEDIFF(DAY,StartDate,ExitDate),0)>0 THEN 0
		WHEN ISNULL(DATEDIFF(DAY,StartDate,ExitDate),0)=0 THEN 1
	END AS [Is_Active_Flag],
	ISNULL(YEAR(StartDate),0) AS [Joining year],
	ISNULL(YEAR(ExitDate),0) AS [Exit year],
	[Start Date Age],
	[Exit Date Age],
	[Age Group],
	[Performance Score] AS [Performance Category],
	CASE
		WHEN (ISNULL(DATEDIFF(DAY,StartDate,ExitDate),0) / 365.0) >= 5 AND	CAST([Current Employee Rating] AS int) >= 3 THEN 'High Value'
		WHEN (ISNULL(DATEDIFF(DAY,StartDate,ExitDate),0) / 365.0) BETWEEN 2 AND 5 AND CAST([Current Employee Rating] AS int)= 3 THEN 'Medium Value'
		ELSE 'Low Value'
	END AS [Employee Lifetime Value],
	CASE 
		WHEN (ISNULL(DATEDIFF(DAY,StartDate,ExitDate),0) / 365.0)>=4.5 THEN 'Senior'
		WHEN (ISNULL(DATEDIFF(DAY,StartDate,ExitDate),0) / 365.0)>=3 THEN 'Mid'
		ELSE 'Junior'
	END AS [Seniority Level],
	CASE	
		WHEN [Tenure Group]='0-1 Year'	THEN 4
		WHEN [Tenure Group]='1-3 Years'	THEN 3
		WHEN [Tenure Group]='3-5 Years'	THEN 2
		WHEN [Tenure Group]='5+ Years'  THEN 1
	END AS [Tenure Risk Score],
	CASE	
		WHEN [Age Group]='Under 25'	THEN 5
		WHEN [Age Group]='35-44'	THEN 4
		WHEN [Age Group]='45-54'	THEN 3
		WHEN [Age Group]='25-34'  THEN 2
		WHEN [Age Group]='55+'  THEN 1
	END AS [Age Risk Score],
		CASE	
		WHEN [Performance Score]='Exceeds'	THEN 4
		WHEN [Performance Score]='Fully Meets'	THEN 3
		WHEN [Performance Score]='Performance Improvement Plan'	THEN 2
		WHEN [Performance Score]='Needs Improvement'  THEN 1
	END AS [Performance Risk Score],
	CASE 
		WHEN ( 	
		CASE	
		WHEN [Tenure Group]='0-1 Year'	THEN 4
		WHEN [Tenure Group]='1-3 Years'	THEN 3
		WHEN [Tenure Group]='3-5 Years'	THEN 2
		WHEN [Tenure Group]='5+ Years'  THEN 1
	END   +
	CASE	
		WHEN [Age Group]='Under 25'	THEN 5
		WHEN [Age Group]='35-44'	THEN 4
		WHEN [Age Group]='45-54'	THEN 3
		WHEN [Age Group]='25-34'  THEN 2
		WHEN [Age Group]='55+'  THEN 1
	END  +
		CASE	
		WHEN [Performance Score]='Exceeds'	THEN 4
		WHEN [Performance Score]='Fully Meets' THEN 3
		WHEN [Performance Score]='Performance Improvement Plan'	THEN 2
		WHEN [Performance Score]='Needs Improvement'  THEN 1
	END)>=7 THEN 'High risk'
	WHEN ( 	
		CASE	
		WHEN [Tenure Group]='0-1 Year'	THEN 4
		WHEN [Tenure Group]='1-3 Years'	THEN 3
		WHEN [Tenure Group]='3-5 Years'	THEN 2
		WHEN [Tenure Group]='5+ Years'  THEN 1
	END   +
	CASE	
		WHEN [Age Group]='Under 25'	THEN 5
		WHEN [Age Group]='35-44'	THEN 4
		WHEN [Age Group]='45-54'	THEN 3
		WHEN [Age Group]='25-34'  THEN 2
		WHEN [Age Group]='55+'  THEN 1
	END  +
		CASE	
		WHEN [Performance Score]='Exceeds'	THEN 4
		WHEN [Performance Score]='Fully Meets'	THEN 3
		WHEN [Performance Score]='Performance Improvement Plan'	THEN 2
		WHEN [Performance Score]='Needs Improvement'  THEN 1
	END) BETWEEN 4 AND 6 THEN 'Medium'
	ELSE 'Low'
	END AS [Retention Risk Category]

FROM gold.vw_hr_employee_data 
;
GO

select * from gold.vw_employee_Data_Report;

