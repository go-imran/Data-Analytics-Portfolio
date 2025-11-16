--SELECT * FROM INFORMATION_SCHEMA.COLUMNS;


IF OBJECT_ID('gold.vw_hr_employee_data', 'V') IS NOT NULL
    DROP VIEW gold.vw_hr_employee_data;
GO

CREATE VIEW gold.vw_hr_employee_data AS
SELECT 
	EmpID,
	FirstName+' '+LastName AS [Full Name],
	StartDate,
	ExitDate,
	CASE 
		WHEN DATEDIFF(YEAR, StartDate, ISNULL(ExitDate, GETDATE())) < 1 THEN '0-1 Year'
		WHEN DATEDIFF(YEAR, StartDate, ISNULL(ExitDate, GETDATE())) BETWEEN 1 AND 3 THEN '1-3 Years'
		WHEN DATEDIFF(YEAR, StartDate, ISNULL(ExitDate, GETDATE())) BETWEEN 3 AND 5 THEN '3-5 Years'
		ELSE '5+ Years'
	END AS [Tenure Group],
	Title AS [Job Title],
	Supervisor,
	ADEmail AS Email,
	BusinessUnit AS [Business Unit],
	CASE 
		WHEN TerminationType='Not Yet' THEN 'Active'
		WHEN EmployeeStatus='Future Start' THEN 'Offer Cancelled'
		ELSE 'Deactive'
	END AS [Employee Status],
	EmployeeType AS [Employee Type],
	PayZone,
	EmployeeClassificationType AS [Employee Classification Type],
	TerminationType AS [Termination Type],
	TerminationDescription AS [Termination Description],
	DepartmentType AS [Department Type],
	Division,
	DOB AS [Date of Birth],
	ISNULL(DATEDIFF(YEAR,DOB,StartDate),0) AS [Start Date Age],
	ISNULL(DATEDIFF(YEAR,DOB,ExitDate),0) AS [Exit Date Age],
	CASE 
		WHEN DATEDIFF(YEAR, DOB, GETDATE()) < 25 THEN 'Under 25'
		WHEN DATEDIFF(YEAR, DOB, GETDATE()) BETWEEN 25 AND 34 THEN '25-34'
		WHEN DATEDIFF(YEAR, DOB, GETDATE()) BETWEEN 35 AND 44 THEN '35-44'
		WHEN DATEDIFF(YEAR, DOB, GETDATE()) BETWEEN 45 AND 54 THEN '45-54'
		ELSE '55+'
	END AS [Age Group],
	State,
	JobFunctionDescription AS [Job Function Description],
	GenderCode AS [Gender Code],
	LocationCode AS [Location Code],
	RaceDesc AS [Race Description],
	MaritalDesc AS [Marital Description],
	PerformanceScore AS [Performance Score],
	CurrentEmployeeRating AS [Current Employee Rating]

FROM silver.hr_employee_data;
GO

IF OBJECT_ID('gold.vw_hr_recruitment_data', 'V') IS NOT NULL
    DROP VIEW gold.vw_hr_recruitment_data;
GO

CREATE VIEW gold.vw_hr_recruitment_data AS
SELECT
    ApplicantID,
	FirstName+' '+LastName AS [Applicant Full Name],
    CASE 
		WHEN Application_Status='Applied' THEN 'Pending Review' 
		ELSE Application_Status
	END AS [Application Status], 
    PrevJobDepartment as [Current Job Department],
    JobTitle as [Current Job Position],
	DesiredSalary AS [Desired Salary],
    ApplicationDate AS [Application Date],
    Gender,
    DateOfBirth AS [Date Of Birth],
	DATEDIFF(YEAR, DateOfBirth, ApplicationDate) AS [Age At Application],
	CASE 
		WHEN DATEDIFF(YEAR, DateOfBirth, GETDATE()) < 25 THEN 'Under 25'
		WHEN DATEDIFF(YEAR, DateOfBirth, GETDATE()) BETWEEN 25 AND 34 THEN '25-34'
		WHEN DATEDIFF(YEAR, DateOfBirth, GETDATE()) BETWEEN 35 AND 44 THEN '35-44'
		WHEN DATEDIFF(YEAR, DateOfBirth, GETDATE()) BETWEEN 45 AND 54 THEN '45-54'
		ELSE '55+'
	END AS [Age Group],
    PhoneNumber AS [PhoneNumber],
    EmailAddress AS [Email],
    Address AS [Current Living Address],
    City AS [Current Living City],
    State AS [Current Living State],
    ZipCode,
    Country AS [Birth Country],
    EducationLevel AS [Education Level],
    YearsOfExperience AS [Years Of Experience]
FROM silver.hr_recruitment_data;
GO

IF OBJECT_ID('gold.vw_hr_employee_training', 'V') IS NOT NULL
    DROP VIEW gold.vw_hr_employee_training;
GO

CREATE VIEW gold.vw_hr_employee_training AS
SELECT
    EmployeeID AS[Employee ID],
    TrainingDate AS [Training Date],
    TrainingProgramName AS [Training Program Name],
    TrainingType AS [Training Type],
    TrainingOutcome AS [Training Outcome],
    Location AS [Training Location],
    Trainer,
    TrainingDuration_Days AS [Training Duration Days],
	    CASE 
        WHEN TrainingDuration_Days = 1 THEN 'Very Short'
        WHEN TrainingDuration_Days IN (2,3) THEN 'Short'
        WHEN TrainingDuration_Days IN (4,5) THEN 'Medium/Long'
        ELSE 'Other'
    END AS [Training Duration Category],
    TrainingCost AS [Training Cost]
FROM silver.hr_employee_training;
GO

IF OBJECT_ID('gold.vw_hr_employee_engagement', 'V') IS NOT NULL
    DROP VIEW gold.vw_hr_employee_engagement;
GO
CREATE VIEW gold.vw_hr_employee_engagement AS
SELECT
    E.EmployeeID AS [Employee ID],
    ED.FirstName + ' ' + ED.LastName AS [Employee Name],
    SurveyDate AS [Survey Date],
    YEAR(SurveyDate) AS [Survey Year],
    MONTH(SurveyDate) AS [Survey Month],
    EngagementScore AS [Engagement Score],
    CASE
        WHEN EngagementScore >= 8 THEN 'High'
        WHEN EngagementScore >= 5 THEN 'Medium'
        ELSE 'Low'
    END AS [Engagement Level],
    SatisfactionScore AS [Satisfaction Score],
    CASE
        WHEN SatisfactionScore >= 8 THEN 'High'
        WHEN SatisfactionScore >= 5 THEN 'Medium'
        ELSE 'Low'
    END AS [Satisfaction Level],
    WorkLifeBalanceScore AS [Work-Life Balance Score],
    CASE
        WHEN WorkLifeBalanceScore >= 8 THEN 'Good'
        WHEN WorkLifeBalanceScore >= 5 THEN 'Average'
        ELSE 'Poor'
    END AS [Work-Life Balance Level],
    DATEDIFF(DAY, SurveyDate, GETDATE()) AS [Days Since Survey]
FROM silver.hr_employee_engagement_survey_data E
LEFT JOIN silver.hr_employee_data ED
    ON E.EmployeeID = ED.EmpID;
GO








