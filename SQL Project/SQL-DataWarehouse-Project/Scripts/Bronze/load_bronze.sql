
/*
===============================================================================
Stored Procedure: Load Bronze Layer (Source -> Bronze)
===============================================================================
Script Purpose:
    This stored procedure loads data into the 'bronze' schema from external CSV files. 
    It performs the following actions:
    - Truncates the bronze tables before loading data.
    - Uses the `BULK INSERT` command to load data from csv Files to bronze tables.

Parameters:
    None. 
	  This stored procedure does not accept any parameters or return any values.

Usage Example:
    EXEC bronze.load_bronze;
===============================================================================
*/
CREATE OR ALTER PROCEDURE bronze.load_bronze AS
BEGIN
	DECLARE @START_TIME DATETIME, @END_TIME DATETIME, @batch_start_time DATETIME, @batch_end_time DATETIME;
	BEGIN TRY
	SET @batch_start_time= GETDATE();
		PRINT'========================================================================';
			PRINT'Loading Bronze Layer';
		PRINT'========================================================================';

		PRINT'<<<<<<<<<<<<<<<<<<<<>>>>>>>>>>>>>>>>>>>>>>>>>>>';
			PRINT'Loading CRM tables';
		PRINT'<<<<<<<<<<<<<<<<<<<<>>>>>>>>>>>>>>>>>>>>>>>>>>>';

		SET @START_TIME=GETDATE();
		PRINT'<<Truncating Table>>>';
		TRUNCATE TABLE bronze.crm_cust_info;

		PRINT '>> Inserting Data Into: bronze.crm_cust_info<<';
		BULK INSERT bronze.crm_cust_info
		FROM 'C:\Users\imran\OneDrive\Desktop\Data analysis project\SQL\SQL Project\SQL-DataWarehouse-Project\Datasets\source_crm\cust_info.csv'
		WITH(
			FIRSTROW=2,
			FIELDTERMINATOR=',',
			TABLOCK
		);
		SET @END_TIME=GETDATE();
		PRINT'>>Table loading time:'+' ' +CAST( DATEDIFF(SECOND, @START_TIME, @END_TIME) AS NVARCHAR) +' seconds';

		SET @START_TIME= GETDATE();
		PRINT'<<Truncating Table>>>';
		TRUNCATE TABLE bronze.crm_prd_info

		PRINT '>> Inserting Data Into: bronze.crm_prd_info<<';
		BULK INSERT bronze.crm_prd_info
		FROM 'C:\Users\imran\OneDrive\Desktop\Data analysis project\SQL\SQL Project\SQL-DataWarehouse-Project\Datasets\source_crm\prd_info.csv'
		WITH(
			FIRSTROW=2,
			FIELDTERMINATOR=',',
			TABLOCK
		);
		SET @END_TIME= GETDATE();
		PRINT'>>Table loading time:'+' ' +CAST( DATEDIFF(SECOND, @START_TIME, @END_TIME) AS NVARCHAR) +' seconds';

		SET @START_TIME=GETDATE();
		PRINT'<<Truncating Table>>>';
		TRUNCATE TABLE bronze.crm_sales_details;

		PRINT '>> Inserting Data Into: bronze.crm_sales_details<<';
		BULK INSERT bronze.crm_sales_details
		FROM 'C:\Users\imran\OneDrive\Desktop\Data analysis project\SQL\SQL Project\SQL-DataWarehouse-Project\Datasets\source_crm\sales_details.csv'
		WITH(
			FIRSTROW=2,
			FIELDTERMINATOR=',',
			TABLOCK
		);
		SET @END_TIME= GETDATE();
		PRINT'>>Table loading time:'+' ' +CAST( DATEDIFF(SECOND, @START_TIME, @END_TIME) AS NVARCHAR) +' seconds';
		PRINT'<<<<<<<<<<<<<<<<<<<<>>>>>>>>>>>>>>>>>>>>>>>>>>>';
			PRINT'Loading ERP tables';
		PRINT'<<<<<<<<<<<<<<<<<<<<>>>>>>>>>>>>>>>>>>>>>>>>>>>';

		SET @START_TIME=GETDATE();
		PRINT'<<Truncating Table>>>';
		TRUNCATE TABLE bronze.erp_cust_az12;

		PRINT '>> Inserting Data Into: bronze.erp_cust_az12<<';
		BULK INSERT bronze.erp_cust_az12
		FROM 'C:\Users\imran\OneDrive\Desktop\Data analysis project\SQL\SQL Project\SQL-DataWarehouse-Project\Datasets\source_erp\CUST_AZ12.csv'
		WITH(
			FIRSTROW=2,
			FIELDTERMINATOR=',',
			TABLOCK
		);
		SET @END_TIME= GETDATE();
		PRINT'>>Table loading time:'+' ' +CAST( DATEDIFF(SECOND, @START_TIME, @END_TIME) AS NVARCHAR) +' seconds';

		SET @START_TIME=GETDATE();
		PRINT'<<Truncating Table>>>';
		TRUNCATE TABLE bronze.erp_loc_a101;

		PRINT '>> Inserting Data Into: bronze.erp_cust_az12<<';
		BULK INSERT bronze.erp_loc_a101
		FROM 'C:\Users\imran\OneDrive\Desktop\Data analysis project\SQL\SQL Project\SQL-DataWarehouse-Project\Datasets\source_erp\LOC_A101.csv'
		WITH(
			FIRSTROW=2,
			FIELDTERMINATOR=',',
			TABLOCK
		);
		SET @END_TIME= GETDATE();
		PRINT'>>Table loading time:'+' ' +CAST( DATEDIFF(SECOND, @START_TIME, @END_TIME) AS NVARCHAR) +' seconds';

		SET @START_TIME=GETDATE();
		PRINT'<<Truncating Table>>>';
		TRUNCATE TABLE bronze.erp_px_cat_g1v2;

		PRINT '>> Inserting Data Into: bronze.erp_px_cat_g1v2<<';
		BULK INSERT bronze.erp_px_cat_g1v2
		FROM 'C:\Users\imran\OneDrive\Desktop\Data analysis project\SQL\SQL Project\SQL-DataWarehouse-Project\Datasets\source_erp\PX_CAT_G1V2.csv'
		WITH(
			FIRSTROW=2,
			FIELDTERMINATOR=',',
			TABLOCK
		);
		SET @END_TIME= GETDATE();
		PRINT'>>Table loading time:'+' ' +CAST( DATEDIFF(SECOND, @START_TIME, @END_TIME) AS NVARCHAR) +' seconds';

		SET @batch_end_time=GETDATE();
		PRINT'\\\\\\\\\\\\\\\\\////////////////////////'
		PRINT'...Loading BRONZE layer is completed...'
		PRINT'>>FULL BRONZE LAYER LOADING TIME:'+' '+ CAST(DATEDIFF(SECOND,@batch_start_time , @batch_end_time) AS NVARCHAR) +' seconds';
		PRINT'\\\\\\\\\\\\\\\\\////////////////////////'
	END TRY
	BEGIN CATCH
		PRINT'\\\\\\\\\\\\\\\\\\\\\//////////////////////////';
		PRINT'ERROR MESSAGE IS :'+' '+ERROR_MESSAGE();
		PRINT'ERROR NUMBER IS :'+' '+CAST(ERROR_NUMBER() AS NVARCHAR);
		PRINT'ERROR STATE IS :'+' '+CAST(ERROR_STATE() AS NVARCHAR);

	END CATCH
	
END

EXEC bronze.load_bronze;