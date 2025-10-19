/*
============================================================
Create Database and Schemas
============================================================

Script Purpose:
    This script creates a new database named 'DataWarehouse' 
    after checking if it already exists. 
    If the database exists, it is dropped and recreated. 
    Additionally, the script sets up three schemas 
    within the database: 'bronze', 'silver', and 'gold'.

WARNING:
    Running this full script will drop the entire 'DataWarehouse' 
    database if it exists. All data in the database will be 
    permanently deleted. Proceed with caution and ensure 
    you have proper backups before running this script.
*/



-- Using master
use master;
GO
-- Dropping database if exists
IF EXISTS (SELECT name FROM sys.databases WHERE name = 'DataWarehouse')
BEGIN
    ALTER DATABASE [DataWarehouse] SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE [DataWarehouse];
END;
GO

-- creating new database
CREATE DATABASE DataWarehouse;
GO

-- createing new schemas
CREATE SCHEMA BRONZE;
GO
CREATE SCHEMA SILVER;
GO 
CREATE SCHEMA GOLD;