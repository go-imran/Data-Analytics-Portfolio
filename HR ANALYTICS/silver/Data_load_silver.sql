/*
===============================================================================
Stored Procedure: Load Silver Layer (Bronze -> Silver)
===============================================================================
Script Purpose:
    This stored procedure performs the ETL (Extract, Transform, Load) process to 
    populate the 'silver' schema tables from the 'bronze' schema.
	Actions Performed:
		- Truncates Silver tables.
		- Inserts transformed and cleansed data from Bronze into Silver tables.
		
Parameters:
    None. 
	This stored procedure does not accept any parameters or return any values.

Usage Example:
    EXEC silver.load_silver;
===============================================================================
*/

CREATE OR ALTER PROCEDURE silver.load_silver AS
BEGIN
    DECLARE @start_time DATETIME, @end_time DATETIME, @batch_start_time DATETIME, @batch_end_time DATETIME;

    BEGIN TRY
        SET @batch_start_time = GETDATE();
        PRINT '================================================';
        PRINT 'Loading Silver Layer';
        PRINT '================================================';

        -------------------------------------------------------------------------
        -- Loading hr_employee_data
        -------------------------------------------------------------------------
        SET @start_time = GETDATE();
        PRINT '>> Truncating Table: silver.hr_employee_data';
        TRUNCATE TABLE silver.hr_employee_data;

        PRINT '>> Inserting Data Into: silver.hr_employee_data';
        INSERT INTO silver.hr_employee_data (
            EmpID,
            FirstName,
            LastName,
            StartDate,
            ExitDate,
            Title,
            Supervisor,
            ADEmail,
            BusinessUnit,
            EmployeeStatus,
            EmployeeType,
            PayZone,
            EmployeeClassificationType,
            TerminationType,
            TerminationDescription,
            DepartmentType,
            Division,
            DOB,
            State,
            JobFunctionDescription,
            GenderCode,
            LocationCode,
            RaceDesc,
            MaritalDesc,
            PerformanceScore,
            CurrentEmployeeRating
        )
        SELECT 
            EmpID,
            FirstName,
            LastName,
            StartDate,
            ExitDate,
            Title,
            Supervisor,
            ADEmail,
            CASE BusinessUnit
                WHEN 'NEL'  THEN 'Network Engineering & Logistics'
                WHEN 'CCDR' THEN 'Corporate Customer & Dealer Relations'
                WHEN 'MSC'  THEN 'Manufacturing & Supply Chain'
                WHEN 'TNS'  THEN 'Technology & Network Services'
                WHEN 'PL'   THEN 'Product Line'
                WHEN 'BPC'  THEN 'Business Process Center'
                WHEN 'EW'   THEN 'Enterprise Works'
                WHEN 'PYZ'  THEN 'Project Yard Zone'
                WHEN 'WBL'  THEN 'Warehouse & Bulk Logistics'
                WHEN 'SVG'  THEN 'Supply & Value Generation'
                ELSE BusinessUnit 
            END AS BusinessUnit,
			CASE 
				WHEN  EmployeeStatus='Active' and TerminationType in ('Retirement', 'Resignation', 'Voluntary', 'Involuntary') THEN 'Deactive'
				WHEN EmployeeStatus='Future Start' THEN REPLACE(EmployeeStatus,'Future Start','Offer Cancelled')
				ELSE EmployeeStatus
			END AS EmployeeStatus,
            EmployeeType,
            PayZone,
            EmployeeClassificationType,
            CASE TerminationType
                WHEN 'Unk' THEN 'Not Yet'
                ELSE TerminationType
            END AS TerminationType,
            ISNULL(TerminationDescription,'N/A') AS TerminationDescription,
            DepartmentType,
            Division,
            DOB,
            CASE State
                WHEN 'TX' THEN 'Texas'
                WHEN 'PA' THEN 'Pennsylvania'
                WHEN 'IN' THEN 'Indiana'
                WHEN 'NH' THEN 'New Hampshire'
                WHEN 'CO' THEN 'Colorado'
                WHEN 'VA' THEN 'Virginia'
                WHEN 'ME' THEN 'Maine'
                WHEN 'RI' THEN 'Rhode Island'
                WHEN 'WA' THEN 'Washington'
                WHEN 'MA' THEN 'Massachusetts'
                WHEN 'NV' THEN 'Nevada'
                WHEN 'NY' THEN 'New York'
                WHEN 'OH' THEN 'Ohio'
                WHEN 'CT' THEN 'Connecticut'
                WHEN 'CA' THEN 'California'
                WHEN 'OR' THEN 'Oregon'
                WHEN 'MT' THEN 'Montana'
                WHEN 'FL' THEN 'Florida'
                WHEN 'VT' THEN 'Vermont'
                WHEN 'AL' THEN 'Alabama'
                WHEN 'ND' THEN 'North Dakota'
                WHEN 'ID' THEN 'Idaho'
                WHEN 'GA' THEN 'Georgia'
                WHEN 'AZ' THEN 'Arizona'
                WHEN 'TN' THEN 'Tennessee'
                WHEN 'NC' THEN 'North Carolina'
                WHEN 'KY' THEN 'Kentucky'
                WHEN 'UT' THEN 'Utah'
                ELSE State
            END AS State,
            CASE JobFunctionDescription
                WHEN 'Cpo' THEN 'Chief Procurement Officer'
                WHEN 'CIO' THEN 'Chief Information Officer'
                WHEN 'VP' THEN 'Vice President'
                WHEN 'CFO' THEN 'Chief Financial Officer'
                WHEN 'EVP' THEN 'Executive Vice President'
                WHEN 'SVP' THEN 'Senior Vice President'
                WHEN 'CEO' THEN 'Chief Executive Officer'
                ELSE JobFunctionDescription
            END AS JobFunctionDescription,
            GenderCode,
            LocationCode,
            RaceDesc,
            MaritalDesc,
            CASE PerformanceScore
                WHEN 'PIP' THEN 'Performance Improvement Plan'
                ELSE PerformanceScore
            END AS PerformanceScore,
            CurrentEmployeeRating
        FROM bronze.hr_employee_data;
        SET @end_time = GETDATE();
        PRINT '>> Load Duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + ' seconds';
        PRINT '>> -------------';

        -------------------------------------------------------------------------
        -- Loading hr_employee_engagement_survey_data
        -------------------------------------------------------------------------
        SET @start_time = GETDATE();
        PRINT '>> Truncating Table: silver.hr_employee_engagement_survey_data';
        TRUNCATE TABLE silver.hr_employee_engagement_survey_data;

        PRINT '>> Inserting Data Into: silver.hr_employee_engagement_survey_data';
        INSERT INTO silver.hr_employee_engagement_survey_data (
            EmployeeID,
            SurveyDate,
            EngagementScore,
            SatisfactionScore,
            WorkLifeBalanceScore
        )
        SELECT 
            EmployeeID,
            SurveyDate,
            EngagementScore,
            SatisfactionScore,
            WorkLifeBalanceScore
        FROM bronze.hr_employee_engagement_survey_data;
        SET @end_time = GETDATE();
        PRINT '>> Load Duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + ' seconds';
        PRINT '>> -------------';

        -------------------------------------------------------------------------
        -- Loading hr_employee_training
        -------------------------------------------------------------------------
        SET @start_time = GETDATE();
        PRINT '>> Truncating Table: silver.hr_employee_training';
        TRUNCATE TABLE silver.hr_employee_training;

        PRINT '>> Inserting Data Into: silver.hr_employee_training';
        INSERT INTO silver.hr_employee_training (
            EmployeeID,
            TrainingDate,
            TrainingProgramName,
            TrainingType,
            TrainingOutcome,
            Location,
            Trainer,
            TrainingDuration_Days,
            TrainingCost
        )
        SELECT
            EmployeeID,
            TrainingDate,
            TrainingProgramName,
            TrainingType,
            TrainingOutcome,
            Location,
            Trainer,
            TrainingDuration_Days,
            TrainingCost
        FROM bronze.hr_employee_training;
        SET @end_time = GETDATE();
        PRINT '>> Load Duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + ' seconds';
        PRINT '>> -------------';

        -------------------------------------------------------------------------
        -- Loading hr_recruitment_data
        -------------------------------------------------------------------------
        SET @start_time = GETDATE();
        PRINT '>> Truncating Table: silver.hr_recruitment_data';
        TRUNCATE TABLE silver.hr_recruitment_data;

        PRINT '>> Inserting Data Into: silver.hr_recruitment_data';
        INSERT INTO silver.hr_recruitment_data (
            ApplicantID,
            ApplicationDate,
            FirstName,
            LastName,
            Gender,
            DateOfBirth,
            PhoneNumber,
            EmailAddress,
            Address,
            City,
            State,
            ZipCode,
            Country,
            EducationLevel,
            YearsOfExperience,
            DesiredSalary,
			Status,
            JobTitle,
            PrevJobDepartment,
            Application_Status
        )
        SELECT 
            ApplicantID,
            ApplicationDate,
            FirstName,
            LastName,
            Gender,
            DateOfBirth,
            CASE
                WHEN PhoneNumber LIKE '%#%' THEN 'N/A'
                WHEN PhoneNumber LIKE '%.%' THEN REPLACE(CAST(PhoneNumber AS VARCHAR),'.','-')
                WHEN PhoneNumber LIKE '%)%' THEN REPLACE(CAST(PhoneNumber AS VARCHAR),')',')-')
                ELSE PhoneNumber
            END AS PhoneNumber,
            EmailAddress,
            Address,
            City,
            CASE State
                WHEN 'AL' THEN 'Alabama'
                WHEN 'AK' THEN 'Alaska'
                WHEN 'AZ' THEN 'Arizona'
                WHEN 'AR' THEN 'Arkansas'
                WHEN 'CA' THEN 'California'
                WHEN 'CO' THEN 'Colorado'
                WHEN 'CT' THEN 'Connecticut'
                WHEN 'DE' THEN 'Delaware'
                WHEN 'DC' THEN 'District of Columbia'
                WHEN 'FL' THEN 'Florida'
                WHEN 'GA' THEN 'Georgia'
                WHEN 'GU' THEN 'Guam'
                WHEN 'HI' THEN 'Hawaii'
                WHEN 'ID' THEN 'Idaho'
                WHEN 'IL' THEN 'Illinois'
                WHEN 'IN' THEN 'Indiana'
                WHEN 'IA' THEN 'Iowa'
                WHEN 'KS' THEN 'Kansas'
                WHEN 'KY' THEN 'Kentucky'
                WHEN 'LA' THEN 'Louisiana'
                WHEN 'ME' THEN 'Maine'
                WHEN 'MD' THEN 'Maryland'
                WHEN 'MA' THEN 'Massachusetts'
                WHEN 'MI' THEN 'Michigan'
                WHEN 'MN' THEN 'Minnesota'
                WHEN 'MS' THEN 'Mississippi'
                WHEN 'MO' THEN 'Missouri'
                WHEN 'MT' THEN 'Montana'
                WHEN 'NE' THEN 'Nebraska'
                WHEN 'NV' THEN 'Nevada'
                WHEN 'NH' THEN 'New Hampshire'
                WHEN 'NJ' THEN 'New Jersey'
                WHEN 'NM' THEN 'New Mexico'
                WHEN 'NY' THEN 'New York'
                WHEN 'NC' THEN 'North Carolina'
                WHEN 'ND' THEN 'North Dakota'
                WHEN 'OH' THEN 'Ohio'
                WHEN 'OK' THEN 'Oklahoma'
                WHEN 'OR' THEN 'Oregon'
                WHEN 'PA' THEN 'Pennsylvania'
                WHEN 'PR' THEN 'Puerto Rico'
                WHEN 'RI' THEN 'Rhode Island'
                WHEN 'SC' THEN 'South Carolina'
                WHEN 'SD' THEN 'South Dakota'
                WHEN 'TN' THEN 'Tennessee'
                WHEN 'TX' THEN 'Texas'
                WHEN 'UT' THEN 'Utah'
                WHEN 'VT' THEN 'Vermont'
                WHEN 'VA' THEN 'Virginia'
                WHEN 'VI' THEN 'U.S. Virgin Islands'
                WHEN 'WA' THEN 'Washington'
                WHEN 'WV' THEN 'West Virginia'
                WHEN 'WI' THEN 'Wisconsin'
                WHEN 'WY' THEN 'Wyoming'
                WHEN 'MP' THEN 'Northern Mariana Islands'
                WHEN 'FM' THEN 'Federated States of Micronesia'
                WHEN 'PW' THEN 'Palau'
                WHEN 'MH' THEN 'Marshall Islands'
                ELSE State
            END AS State,
            ZipCode,
            Country,
            EducationLevel,
            YearsOfExperience,
            DesiredSalary,
			Status,
			TRIM(REPLACE(JobTitle,'"','')) AS JobTitle,
			CASE 
				WHEN 
					LTRIM(RTRIM(
						CASE 
							WHEN CHARINDEX('",', CAST(Status AS VARCHAR(MAX))) > 2 THEN 
								SUBSTRING(CAST(Status AS VARCHAR(MAX)), 2, CHARINDEX('",', CAST(Status AS VARCHAR(MAX))) - 2)
							ELSE 
								CAST(Status AS VARCHAR(MAX))
						END
					)) IN ('Interviewing','In Review','Rejected','Offered','Applied')
				THEN 'Not Mentioned'
    
				ELSE 
					LTRIM(RTRIM(
						CASE 
							WHEN CHARINDEX('",', CAST(Status AS VARCHAR(MAX))) > 2 THEN 
								SUBSTRING(CAST(Status AS VARCHAR(MAX)), 2, CHARINDEX('",', CAST(Status AS VARCHAR(MAX))) - 2)
							ELSE 
								CAST(Status AS VARCHAR(MAX))
						END
					))
			END AS [Previous Job Department],
            LTRIM(RTRIM(
                CASE 
                    WHEN CHARINDEX('",', CAST(Status AS VARCHAR(MAX))) > 0
                    THEN SUBSTRING(CAST(Status AS VARCHAR(MAX)), CHARINDEX('",', CAST(Status AS VARCHAR(MAX))) + 2, LEN(CAST(Status AS VARCHAR(MAX))))
                    ELSE CAST(Status AS VARCHAR(MAX))
                END
            )) AS [Application Status]
        FROM bronze.hr_recruitment_data;
        SET @end_time = GETDATE();
        PRINT '>> Load Duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + ' seconds';
        PRINT '>> -------------';

        -------------------------------------------------------------------------
        -- End of Silver Load
        -------------------------------------------------------------------------
        SET @batch_end_time = GETDATE();
        PRINT '==========================================';
        PRINT 'Loading Silver Layer is Completed';
        PRINT '   - Total Load Duration: ' + CAST(DATEDIFF(SECOND, @batch_start_time, @batch_end_time) AS NVARCHAR) + ' seconds';
        PRINT '==========================================';

    END TRY
    BEGIN CATCH
        PRINT '==========================================';
        PRINT 'ERROR OCCURRED DURING LOADING SILVER LAYER';
        PRINT 'Error Message: ' + ERROR_MESSAGE();
        PRINT 'Error Number: ' + CAST(ERROR_NUMBER() AS NVARCHAR);
        PRINT 'Error State: ' + CAST(ERROR_STATE() AS NVARCHAR);
        PRINT '==========================================';
    END CATCH
END
