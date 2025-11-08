/*********************************************************************************************
   PROJECT: HR ANALYTICS DATA PIPELINE – BRONZE LAYER DATA LOAD PROCEDURE
   -------------------------------------------------------------------------------------------
   PROCEDURE NAME:
       bronze.hr_data_load_bronze

   PURPOSE:
       This stored procedure automates the ETL (Extract–Transform–Load) process for loading
       raw HR data into the Bronze Layer of the HR Analytics Data Warehouse.

       For each HR data table, the procedure:
           1. Truncates existing data to remove old records.
           2. Loads fresh data from corresponding CSV files using BULK INSERT.
           3. Logs the start time, end time, and duration for each load operation.

   SCHEMA:
       bronze (Raw Data Layer)

   WARNING:
       This procedure truncates and reloads all Bronze Layer tables.
       All existing data in these tables will be permanently deleted and replaced.
       Execute this procedure only in a development or staging environment,
       and ensure all CSV paths and file permissions are correct.

   FILE LOCATIONS (example paths used below):
       - Employee Data:                C:\sql\dwh_project\datasets\source_crm\cust_info.csv
       - Employee Engagement Survey:   C:\sql\dwh_project\datasets\source_crm\prd_info.csv
       - Recruitment Data:             C:\sql\dwh_project\datasets\source_crm\sales_details.csv
       - Employee Training:            C:\sql\dwh_project\datasets\source_erp\loc_a101.csv

   EXCEPTION HANDLING:
       Includes TRY...CATCH block to handle and print error messages during data load.

*********************************************************************************************/

CREATE OR ALTER PROCEDURE bronze.hr_data_load_bronze AS
BEGIN
    DECLARE 
        @start_time DATETIME, 
        @end_time DATETIME, 
        @batch_start_time DATETIME, 
        @batch_end_time DATETIME; 

    BEGIN TRY
        SET @batch_start_time = GETDATE();

        PRINT '================================================';
        PRINT 'Starting Data Load into Bronze Layer';
        PRINT '================================================';

        --------------------------------------------------------------
        -- Load Employee Data
        --------------------------------------------------------------
        PRINT '------------------------------------------------';
        PRINT 'Loading Table: bronze.hr_employee_data';
        PRINT '------------------------------------------------';
        SET @start_time = GETDATE();

        PRINT 'Truncating existing data from bronze.hr_employee_data...';
        TRUNCATE TABLE bronze.hr_employee_data;

        PRINT 'Inserting new data from file: employee_data.csv';
        BULK INSERT bronze.hr_employee_data
        FROM 'C:\SQLData\HR_Datasets\employee_data.csv'
        WITH (
            FIRSTROW = 2,
            FIELDTERMINATOR = ',',
            TABLOCK
        );

        SET @end_time = GETDATE();
        PRINT 'Load completed. Duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + ' seconds';
        PRINT '------------------------------------------------';


        --------------------------------------------------------------
        -- Load Employee Engagement Survey Data
        --------------------------------------------------------------
        PRINT '------------------------------------------------';
        PRINT 'Loading Table: bronze.hr_employee_engagement_survey_data';
        PRINT '------------------------------------------------';
        SET @start_time = GETDATE();

        PRINT 'Truncating existing data from bronze.hr_employee_engagement_survey_data...';
        TRUNCATE TABLE bronze.hr_employee_engagement_survey_data;

        PRINT 'Inserting new data from file: employee_engagement_survey_data.csv';
        BULK INSERT bronze.hr_employee_engagement_survey_data
        FROM 'C:\SQLData\HR_Datasets\employee_engagement_survey_data.csv'
        WITH (
            FIRSTROW = 2,
            FIELDTERMINATOR = ',',
            TABLOCK
        );

        SET @end_time = GETDATE();
        PRINT 'Load completed. Duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + ' seconds';
        PRINT '------------------------------------------------';


        --------------------------------------------------------------
        -- Load Recruitment Data
        --------------------------------------------------------------
        PRINT '------------------------------------------------';
        PRINT 'Loading Table: bronze.hr_recruitment_data';
        PRINT '------------------------------------------------';
        SET @start_time = GETDATE();

        PRINT 'Truncating existing data from bronze.hr_recruitment_data...';
        TRUNCATE TABLE bronze.hr_recruitment_data;

        PRINT 'Inserting new data from file: recruitment_data.csv';
        BULK INSERT bronze.hr_recruitment_data
        FROM 'C:\SQLData\HR_Datasets\recruitment_data.csv'
        WITH (
            FIRSTROW = 2,
            FIELDTERMINATOR = ',',
            TABLOCK
        );

        SET @end_time = GETDATE();
        PRINT 'Load completed. Duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + ' seconds';
        PRINT '------------------------------------------------';


        --------------------------------------------------------------
        -- Load Employee Training Data
        --------------------------------------------------------------
        PRINT '------------------------------------------------';
        PRINT 'Loading Table: bronze.hr_employee_training';
        PRINT '------------------------------------------------';
        SET @start_time = GETDATE();

        PRINT 'Truncating existing data from bronze.hr_employee_training...';
        TRUNCATE TABLE bronze.hr_employee_training;

        PRINT 'Inserting new data from file: employee_training.csv';
        BULK INSERT bronze.hr_employee_training
        FROM 'C:\SQLData\HR_Datasets\training_and_development_data.csv'
        WITH (
            FIRSTROW = 2,
            FIELDTERMINATOR = ',',
            TABLOCK
        );

        SET @end_time = GETDATE();
        PRINT 'Load completed. Duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + ' seconds';
        PRINT '------------------------------------------------';


        --------------------------------------------------------------
        -- Completion Message
        --------------------------------------------------------------
        SET @batch_end_time = GETDATE();

        PRINT '================================================';
        PRINT 'Data Load into Bronze Layer Completed Successfully';
        PRINT 'Total Load Duration: ' + CAST(DATEDIFF(SECOND, @batch_start_time, @batch_end_time) AS NVARCHAR) + ' seconds';
        PRINT '================================================';

    END TRY

    BEGIN CATCH
        PRINT '================================================';
        PRINT 'ERROR OCCURRED DURING BRONZE LAYER DATA LOAD';
        PRINT 'Error Message: ' + ERROR_MESSAGE();
        PRINT 'Error Number: ' + CAST(ERROR_NUMBER() AS NVARCHAR);
        PRINT 'Error State: ' + CAST(ERROR_STATE() AS NVARCHAR);
        PRINT '================================================';
    END CATCH
END;
GO
