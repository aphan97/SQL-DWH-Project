--PROJECT: SQL DWH
--Project Initialization: Create DB 'DataWarehouse'. Drop existing DB with same name

/*
	SCRIPT PURPOSE: 
		-Creates a new DB named 'DataWarehouse' after checking if it already exists. If DB exists then it is dropped
		and recreated.
		-Sets up 3 schemas in database: bronze, silver, and gold.

***Running this script will drop the entire 'DataWarehouse' database if it exists. 
    All data in the database will be permanently deleted. Proceed with caution 
    and ensure you have proper backups before running this script.***
*/

USE master;
GO

--Drop and recreate 'DataWarehouse' database
IF EXISTS (SELECT 1 FROM sys.databases WHERE name = 'DataWarehouse')
BEGIN
	ALTER DATABASE DataWarehouse SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
	DROP DATABASE DataWarehouse;
END;
GO

--Create 'DataWarehouse' DB
CREATE DATABASE DataWarehouse;

USE DataWarehouse;
GO
--Create All Schemas
CREATE SCHEMA bronze;
GO
CREATE SCHEMA silver;
GO
CREATE SCHEMA gold;
GO
