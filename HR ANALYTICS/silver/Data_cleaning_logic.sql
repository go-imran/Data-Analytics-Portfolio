/*
Check for NULLS OR DUPLICATES in primary key
EXPECTATIONS: NO Result
*/

SELECT TOP 100 
TerminationDescription,
ExitDate,
ISNULL(TerminationDescription,'N/A')
FROM bronze.hr_employee_data;

SELECT 
	EmpID,
	COUNT(*) 
FROM bronze.hr_employee_data
GROUP BY EmpID
HAVING COUNT(*)>1;

-- Check for unwanted spece
-- Expectations: NO Result
SELECT 
*
FROM bronze.hr_employee_data
WHERE DepartmentType<>TRIM(DepartmentType);

--Data standarization & consistency

SELECT PhoneNumber,
LEN(CAST(PhoneNumber AS VARCHAR)),
CHARINDEX(')',PhoneNumber),
REPLACE(CAST(PhoneNumber AS VARCHAR),')',')-')
FROM bronze.hr_recruitment_data
WHERE PhoneNumber LIKE '%)%';

SELECT EmailAddress,
	   SUBSTRING(EmailAddress,CHARINDEX('@',EmailAddress),LEN(EmailAddress))
FROM bronze.hr_recruitment_data
;



SELECT 'BusinessUnit' as ColumnName,
STRING_AGG(BusinessUnit,',') AS [All_comma_Separeted_distinct_values]
FROM
(SELECT DISTINCT BusinessUnit
FROM bronze.hr_employee_data) T

union all

SELECT 'EmployeeStatus' as ColumnName,
STRING_AGG(EmployeeStatus,',') AS [All_comma_Separeted_distinct_values]
FROM
(SELECT DISTINCT EmployeeStatus
FROM bronze.hr_employee_data) T

union all

SELECT 'EmployeeType' as ColumnName,
STRING_AGG(EmployeeType,',') AS [All_comma_Separeted_distinct_values]
FROM
(SELECT DISTINCT EmployeeType
FROM bronze.hr_employee_data) T

union all

SELECT 'EmployeeClassificationType' as ColumnName,
STRING_AGG(EmployeeClassificationType,',') AS [All_comma_Separeted_distinct_values]
FROM
(SELECT DISTINCT EmployeeClassificationType
FROM bronze.hr_employee_data) T

union all

SELECT 'DepartmentType' as ColumnName,
STRING_AGG(DepartmentType,',') AS [All_comma_Separeted_distinct_values]
FROM
(SELECT DISTINCT DepartmentType
FROM bronze.hr_employee_data) T

union all

SELECT 'JobFunctionDescription' as ColumnName,
STRING_AGG(JobFunctionDescription,',') AS [All_comma_Separeted_distinct_values]
FROM
(SELECT DISTINCT JobFunctionDescription
FROM bronze.hr_employee_data) T

union all

SELECT 'GenderCode' as ColumnName,
STRING_AGG(GenderCode,',') AS [All_comma_Separeted_distinct_values]
FROM
(SELECT DISTINCT GenderCode
FROM bronze.hr_employee_data) T

union all

SELECT 'RaceDesc' as ColumnName,
STRING_AGG(RaceDesc,',') AS [All_comma_Separeted_distinct_values]
FROM
(SELECT DISTINCT RaceDesc
FROM bronze.hr_employee_data) T

union all

SELECT 'MaritalDesc' as ColumnName,
STRING_AGG(MaritalDesc,',') AS [All_comma_Separeted_distinct_values]
FROM
(SELECT DISTINCT MaritalDesc
FROM bronze.hr_employee_data) T

union all

SELECT 'PerformanceScore' as ColumnName,
STRING_AGG(PerformanceScore,',') AS [All_comma_Separeted_distinct_values]
FROM
(SELECT DISTINCT PerformanceScore
FROM bronze.hr_employee_data) T

UNION ALL
SELECT 'State' as ColumnName,
STRING_AGG(State,',') AS [All_comma_Separeted_distinct_values]
FROM
(SELECT DISTINCT State
FROM bronze.hr_employee_data) T

UNION ALL
SELECT 'TerminationType' as ColumnName,
STRING_AGG(TerminationType,',') AS [All_comma_Separeted_distinct_values]
FROM
(SELECT DISTINCT TerminationType
FROM bronze.hr_employee_data) T
;


select distinct cast(city as varchar) as city, cast(state as varchar)as state, cast(Country as varchar) as country
from bronze.hr_recruitment_data;
-- Date checking...
SELECT *
FROM bronze.hr_employee_data
WHERE StartDate>ExitDate AND ExitDate IS NOT NULL;

SELECT *
FROM bronze.hr_employee_data
WHERE DOB>GETDATE() OR DOB<(SELECT MIN(DOB) FROM bronze.hr_employee_data);


-- checking negative values------------
SELECT TrainingCost
FROM bronze.hr_employee_training
WHERE TrainingCost<=0
;

SELECT TOP 10 * FROM bronze.hr_recruitment_data;

SELECT COLUMN_NAME, DATA_TYPE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'hr_recruitment_data';


--distinct value finding-----------
select 
	JobTitle,
	Trim(REPLACE(JobTitle,'"',''))
from bronze.hr_recruitment_data;


select cast(Status as varchar),
TRIM(cast(Status as varchar))
from bronze.hr_recruitment_data
where cast(Status as varchar) !=TRIM(cast(Status as varchar));

SELECT 
    TRIM(CAST(Status AS VARCHAR)) AS TrimmedStatus,
    CASE 
        WHEN CHARINDEX('"', TRIM(CAST(Status AS VARCHAR))) > 0 
        THEN SUBSTRING(
                TRIM(CAST(Status AS VARCHAR)),
                1,
                CHARINDEX('"', TRIM(CAST(Status AS VARCHAR))) - 1
             )
        ELSE TRIM(CAST(Status AS VARCHAR))
    END AS CleanStatus
FROM bronze.hr_recruitment_data;





SELECT 
distinct cast(status as varchar)
FROM bronze.hr_recruitment_data;

SELECT
    LTRIM(RTRIM(
        CASE 
            WHEN CHARINDEX('",', CAST(Status AS VARCHAR(MAX))) > 2 
            THEN SUBSTRING(CAST(Status AS VARCHAR(MAX)), 2, CHARINDEX('",', CAST(Status AS VARCHAR(MAX))) - 2)
            ELSE CAST(Status AS VARCHAR(MAX))
        END
    )) AS Position,
    LTRIM(RTRIM(
        CASE 
            WHEN CHARINDEX('",', CAST(Status AS VARCHAR(MAX))) > 0
            THEN SUBSTRING(CAST(Status AS VARCHAR(MAX)), CHARINDEX('",', CAST(Status AS VARCHAR(MAX))) + 2, LEN(CAST(Status AS VARCHAR(MAX))))
            ELSE NULL
        END
    )) AS Application_Status
FROM bronze.hr_recruitment_data;


