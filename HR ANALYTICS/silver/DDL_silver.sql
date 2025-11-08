/*********************************************************************************************
   PROJECT: HR ANALYTICS DATA MODEL – SILVER LAYER TABLE CREATION SCRIPT
   -------------------------------------------------------------------------------------------
   PURPOSE:
       This script creates the foundational ("silver") layer tables for an HR Analytics project.
       These tables store **raw, untransformed employee data** that will later feed into 
       Power BI dashboards, SQL transformations (silver layer), and Python-based analysis.

   TABLES CREATED:
       1️. silver.hr_employee_data                   → Master Employee Information  
       2️. silver.hr_employee_engagement_survey_data → Employee Engagement & Satisfaction Metrics  
       3️. silver.hr_recruitment_data                → Recruitment & Applicant Information  
       4️. silver.hr_employee_training               → Employee Training History  

   LOGIC OVERVIEW:
       • Checks if each table exists using OBJECT_ID().
       • Drops the existing table (if found).
       • Creates a new table with clean structure and proper data types.
       • Follows consistent naming convention and schema organization.

   NOTES:
       • All tables are placed under schema: `silver` (Raw Data Layer).
       • NVARCHAR is used for flexibility (supports multilingual text).
       • DECIMAL ensures accuracy for scores, salary, and costs.
       • Aligns with ELT/ETL best practices for analytical pipelines.

   WARNING:
       This script DROPS existing tables before creating new ones.
       All data in these tables will be permanently deleted upon execution.
       Run this script **only in a development or staging environment**, not in production.

*********************************************************************************************/



-----------------------------
-- EMPLOYEE MASTER DATA
-----------------------------
IF OBJECT_ID('silver.hr_employee_data', 'U') IS NOT NULL
BEGIN
    PRINT 'Table silver.hr_employee_data already exists. Dropping existing table...';
    DROP TABLE silver.hr_employee_data;
END
GO

CREATE TABLE silver.hr_employee_data (
    EmpID                       NVARCHAR(50),
    FirstName                   NVARCHAR(100),
    LastName                    NVARCHAR(100),
    StartDate                   DATE,
    ExitDate                    DATE NULL,
    Title                       NVARCHAR(100),
    Supervisor                  NVARCHAR(100),
    ADEmail                     NVARCHAR(150),
    BusinessUnit                NVARCHAR(100),
    EmployeeStatus              NVARCHAR(50),
    EmployeeType                NVARCHAR(50),
    PayZone                     NVARCHAR(50),
    EmployeeClassificationType  NVARCHAR(100),
    TerminationType             NVARCHAR(100),
    TerminationDescription      NVARCHAR(255),
    DepartmentType              NVARCHAR(100),
    Division                    NVARCHAR(100),
    DOB                         DATE,
    State                       NVARCHAR(100),
    JobFunctionDescription      NVARCHAR(150),
    GenderCode                  NVARCHAR(20),
    LocationCode                NVARCHAR(50),
    RaceDesc                    NVARCHAR(100),
    MaritalDesc                 NVARCHAR(50),
    PerformanceScore            NVARCHAR(50),
    CurrentEmployeeRating       DECIMAL(3,2)
);
PRINT 'Table silver.hr_employee_data created successfully.';
GO


-----------------------------------------------
-- EMPLOYEE ENGAGEMENT SURVEY DATA
-----------------------------------------------
IF OBJECT_ID('silver.hr_employee_engagement_survey_data', 'U') IS NOT NULL
BEGIN
    PRINT 'Table silver.hr_employee_engagement_survey_data already exists. Dropping existing table...';
    DROP TABLE silver.hr_employee_engagement_survey_data;
END
GO

CREATE TABLE silver.hr_employee_engagement_survey_data (
    EmployeeID          INT,
    SurveyDate          DATE,
    EngagementScore     DECIMAL(4,2),
    SatisfactionScore   DECIMAL(4,2),
    WorkLifeBalanceScore DECIMAL(4,2)
);
PRINT 'Table silver.hr_employee_engagement_survey_data created successfully.';
GO


-----------------------------------------------
--HR RECRUITMENT DATA
-----------------------------------------------
IF OBJECT_ID('silver.hr_recruitment_data', 'U') IS NOT NULL
BEGIN
    PRINT 'Table silver.hr_recruitment_data already exists. Dropping existing table...';
    DROP TABLE silver.hr_recruitment_data;
END
GO

CREATE TABLE silver.hr_recruitment_data (
    ApplicantID         NVARCHAR(50),
    ApplicationDate     DATE,
    FirstName           NVARCHAR(100),
    LastName            NVARCHAR(100),
    Gender              NVARCHAR(20),
    DateOfBirth         DATE,
    PhoneNumber         TEXT,
    EmailAddress        NVARCHAR(150),
    Address             TEXT,
    City                NVARCHAR(100),
    State               NVARCHAR(50),
    ZipCode             NVARCHAR(20),
    Country             TEXT,
    EducationLevel      NVARCHAR(100),
    YearsOfExperience   DECIMAL(4,1),
    DesiredSalary       DECIMAL(10,2),
    JobTitle            NVARCHAR(100),
    Status              TEXT
);
PRINT 'Table silver.hr_recruitment_data created successfully.';
GO


-----------------------------------------------
--EMPLOYEE TRAINING DATA
-----------------------------------------------
IF OBJECT_ID('silver.hr_employee_training', 'U') IS NOT NULL
BEGIN
    PRINT 'Table silver.hr_employee_training already exists. Dropping existing table...';
    DROP TABLE silver.hr_employee_training;
END
GO

CREATE TABLE silver.hr_employee_training (
    EmployeeID              NVARCHAR(50),
    TrainingDate            DATE,
    TrainingProgramName     NVARCHAR(150),
    TrainingType            NVARCHAR(100),
    TrainingOutcome         NVARCHAR(50),
    Location                NVARCHAR(100),
    Trainer                 NVARCHAR(100),
    TrainingDuration_Days   INT,
    TrainingCost            DECIMAL(10,2)
);
PRINT 'Table silver.hr_employee_training created successfully.';
GO
