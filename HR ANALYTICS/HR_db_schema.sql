/*
-------------------------------------------------------------------------------------
Purpose: 
This script creates a fresh SQL Server database called 'HR_ANALYTICS' for HR analytics 
projects and defines three schemas (bronze, silver, gold) for implementing a 
data warehouse structure (Bronze → Silver → Gold layers).

Warning:
1. This script **drops the existing HR_ANALYTICS database** if it exists, 
   which will delete all existing data permanently.
2. Use with caution in production environments. Recommended only for 
   development or testing environments.
-------------------------------------------------------------------------------------
*/

-- Switch context to the master database as operations like CREATE DATABASE require it
USE master;

-- Check if a database named 'HR_ANALYTICS' already exists
IF EXISTS(SELECT 1 FROM SYS.databases WHERE NAME='HR_ANALYTICS')
BEGIN
    -- Set the database to SINGLE_USER mode to immediately rollback any active connections
    ALTER DATABASE HR_ANALYTICS SET SINGLE_USER WITH ROLLBACK IMMEDIATE;

    -- Drop the existing database to start fresh
    DROP DATABASE HR_ANALYTICS;
END

-- Create a new database named 'HR_ANALYTICS'
CREATE DATABASE HR_ANALYTICS;
GO

-- Switch context to the newly created database to define schemas
USE HR_ANALYTICS;
GO

-- Drop schemas if they exist
IF EXISTS (SELECT * FROM sys.schemas WHERE name = 'bronze')
    DROP SCHEMA bronze;
IF EXISTS (SELECT * FROM sys.schemas WHERE name = 'silver')
    DROP SCHEMA silver;
IF EXISTS (SELECT * FROM sys.schemas WHERE name = 'gold')
    DROP SCHEMA gold;
GO
-- Create a schema named 'bronze' for storing raw/unprocessed data
CREATE SCHEMA bronze;
GO 

-- Create a schema named 'silver' for storing cleaned and standardized data
CREATE SCHEMA silver;
GO

-- Create a schema named 'gold' for storing aggregated and analytics-ready data
CREATE SCHEMA gold;
GO
