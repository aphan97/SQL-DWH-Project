--BRONZE LAYER

/*
	Analysing:
		-Interview source system experts
	Coding:
		-Data ingestion: Find a way to load the data from source into DWH
	Validation:
		-Data completeness and schema check (quality control)
		-Schema: a collection of rules that the database will enforce for you. This is beneficial because 
				 it allows you to ensure that all of the schema data in your database is valid and that 
				 relationships are enforced without having to add application code to enforce those rules.
	Docs & Version:
		-Data documenting versioning in GIT
*/

/*
	Analyze Source Systems

		Business context and ownership:
			-Who owns the data?
			-What business process does it support?
			-System and data documentation
			-Data model and data catalog
	
		Architecture and Tech Stack:
			-How is the data stored? (SQL Server, oracle, AWS, azure, etc.)
			-What are the integration? capabilities? (API, kafka, file extract, direct db, etc.)
	
		Extract and load:
			-Incremental or full load?
			-Data scope and historical needs
			-What is the expected size of extracts?
			-Are there any data volume limitations?
			-How to avoid impacting the source system's performance
			-Authentication and authorization (tokens, ssh keys, vpn, etc.)
*/


--Create DDL For Tables From ALL Source Files in CRM and ERP Systems: DDL defines structure of DB tables

IF OBJECT_ID ('bronze.crm_cust_info', 'U') IS NOT NULL
	DROP TABLE bronze.crm_cust_info;
CREATE TABLE bronze.crm_cust_info (
	cst_id INT,
	cst_key NVARCHAR(50),
	cst_firstname NVARCHAR(50),
	cst_lastname NVARCHAR(50),
	cst_marital_status NVARCHAR(50),
	cst_gndr NVARCHAR(50),
	cst_create_date DATE
);

IF OBJECT_ID ('bronze.crm_prd_info', 'U') IS NOT NULL
	DROP TABLE bronze.crm_prd_info;
CREATE TABLE bronze.crm_prd_info (
	prd_id INT NOT NULL,
	prd_key NVARCHAR(50),
	prd_nm NVARCHAR(50),
	prd_cost INT,
	prd_line NVARCHAR(50),
	prd_start_dt DATE,
	prd_end_dt DATE,
);

IF OBJECT_ID ('bronze.crm_sales_details', 'U') IS NOT NULL
	DROP TABLE bronze.crm_sales_details;
CREATE TABLE bronze.crm_sales_details (
	sls_ord_num NVARCHAR(50),
	sls_prd_key NVARCHAR(50),
	sls_cust_id INT,
	sls_order_dt INT,
	sls_ship_dt INT,
	sls_due_dt INT,
	sls_sales INT,
	sls_quantity INT,
	sls_price INT,
);

IF OBJECT_ID ('bronze.erp_loc_a101', 'U') IS NOT NULL
	DROP TABLE bronze.erp_loc_a101;
CREATE TABLE bronze.erp_loc_a101 (
	cid NVARCHAR(50),
	cntry NVARCHAR(50)
);

IF OBJECT_ID ('bronze.erp_cust_az12', 'U') IS NOT NULL
	DROP TABLE bronze.erp_cust_az12;
CREATE TABLE bronze.erp_cust_az12 (
	cid NVARCHAR(50),
	bdate DATE,
	gen NVARCHAR(50)
);

IF OBJECT_ID ('bronze.erp_px_cat_g1v2', 'U') IS NOT NULL
	DROP TABLE bronze.erp_px_cat_g1v2;
CREATE TABLE bronze.erp_px_cat_g1v2 (
	id NVARCHAR(50),
	cat NVARCHAR(50),
	subcat NVARCHAR(50),
	maintenance NVARCHAR(50)
);

--Develop SQL Load Scripts
--Bulk Insert: Method to load massive amounts of data from files directly into a database


--Putting load scripts into a stored procedure
CREATE OR ALTER PROCEDURE bronze.load_bronze AS
BEGIN
	DECLARE @start_time DATETIME, @end_time DATETIME, @batch_start_time DATETIME, @batch_end_time DATETIME --Declare variables to track duration of procedure
	BEGIN TRY --Put entire procedure in try block for error handling
		SET @batch_start_time =GETDATE();
		PRINT 'Loading Bronze Layer'; --Message to clarify procedure executed
		PRINT 'Loading CRM Tables';

		SET @start_time = GETDATE();
		--cust_info Table
		PRINT '>>Truncating Table: bronze.crm_cust_info';
		TRUNCATE TABLE bronze.crm_cust_info --Empties table before loading data

		PRINT '>>Loading Table: bronze.crm_cust_info';
		BULK INSERT bronze.crm_cust_info
		FROM 'C:\Users\aphan\Documents\Career\SQL\2\Projects\sql-data-warehouse-project\sql-data-warehouse-project\datasets\source_crm\cust_info.csv'
		WITH (
			FIRSTROW = 2, --Since first row is the header, this tells SQL to start at the second row
			FIELDTERMINATOR = ',', --Tells SQL how each row is separated in file
			TABLOCK --Locks table while SQL is loading it. Improves performance
		);
		SET @end_time = GETDATE();
		PRINT '>> Load Duration: ' + CAST(DATEDIFF(second, @start_time,@end_time) AS NVARCHAR) + ' seconds';

		--prd_info Table
		SET @start_time = GETDATE();
		PRINT '>>Truncating Table: bronze.crm_prd_info';
		TRUNCATE TABLE bronze.crm_prd_info --Empties table before loading data

		PRINT '>>Loading Table: bronze.crm_prd_info';
		BULK INSERT bronze.crm_prd_info
		FROM 'C:\Users\aphan\Documents\Career\SQL\2\Projects\sql-data-warehouse-project\sql-data-warehouse-project\datasets\source_crm\prd_info.csv'
		WITH (
			FIRSTROW = 2, --Since first row is the header, this tells SQL to start at the second row
			FIELDTERMINATOR = ',', --Tells SQL how each row is separated in file
			TABLOCK --Locks table while SQL is loading it. Improves performance
		);
		SET @end_time = GETDATE();
		PRINT '>> Load Duration: ' + CAST(DATEDIFF(second, @start_time,@end_time) AS NVARCHAR) + ' seconds';

		--sales_details Table
		SET @start_time = GETDATE();
		PRINT '>>Truncating Table: bronze.crm_sales_details';
		TRUNCATE TABLE bronze.crm_sales_details --Empties table before loading data

		PRINT '>>Loading Table: bronze.crm_sales_details';
		BULK INSERT bronze.crm_sales_details
		FROM 'C:\Users\aphan\Documents\Career\SQL\2\Projects\sql-data-warehouse-project\sql-data-warehouse-project\datasets\source_crm\sales_details.csv'
		WITH (
			FIRSTROW = 2, --Since first row is the header, this tells SQL to start at the second row
			FIELDTERMINATOR = ',', --Tells SQL how each row is separated in file
			TABLOCK --Locks table while SQL is loading it. Improves performance
		);
		SET @end_time = GETDATE();
		PRINT '>> Load Duration: ' + CAST(DATEDIFF(second, @start_time,@end_time) AS NVARCHAR) + ' seconds';

		PRINT 'Loading ERP Tables';

		--loc_a101 Table
		SET @start_time = GETDATE();
		PRINT '>>Truncating Table: bronze.erp_loc_a101';
		TRUNCATE TABLE bronze.erp_loc_a101 --Empties table before loading data

		PRINT '>>Loading Table: bronze.erp_loc_a101';
		BULK INSERT bronze.erp_loc_a101
		FROM 'C:\Users\aphan\Documents\Career\SQL\2\Projects\sql-data-warehouse-project\sql-data-warehouse-project\datasets\source_erp\LOC_A101.csv'
		WITH (
			FIRSTROW = 2, --Since first row is the header, this tells SQL to start at the second row
			FIELDTERMINATOR = ',', --Tells SQL how each row is separated in file
			TABLOCK --Locks table while SQL is loading it. Improves performance
		);
		SET @end_time = GETDATE();
		PRINT '>> Load Duration: ' + CAST(DATEDIFF(second, @start_time,@end_time) AS NVARCHAR) + ' seconds';

		--cust_az12 Table
		SET @start_time = GETDATE();
		PRINT '>>Truncating Table: bronze.cust_az12';
		TRUNCATE TABLE bronze.erp_cust_az12 --Empties table before loading data

		PRINT '>>Loading Table: bronze.cust_az12';
		BULK INSERT bronze.erp_cust_az12
		FROM 'C:\Users\aphan\Documents\Career\SQL\2\Projects\sql-data-warehouse-project\sql-data-warehouse-project\datasets\source_erp\cust_az12.csv'
		WITH (
			FIRSTROW = 2, --Since first row is the header, this tells SQL to start at the second row
			FIELDTERMINATOR = ',', --Tells SQL how each row is separated in file
			TABLOCK --Locks table while SQL is loading it. Improves performance
		);
		SET @end_time = GETDATE();
		PRINT '>> Load Duration: ' + CAST(DATEDIFF(second, @start_time,@end_time) AS NVARCHAR) + ' seconds';

		--px_cat_g1v2 Table
		SET @start_time = GETDATE();
		PRINT '>>Truncating Table: bronze.px_cat_g1v2';
		TRUNCATE TABLE bronze.erp_px_cat_g1v2 --Empties table before loading data

		PRINT '>>Loading Table: bronze.px_cat_g1v2';
		BULK INSERT bronze.erp_px_cat_g1v2
		FROM 'C:\Users\aphan\Documents\Career\SQL\2\Projects\sql-data-warehouse-project\sql-data-warehouse-project\datasets\source_erp\px_cat_g1v2.csv'
		WITH (
			FIRSTROW = 2, --Since first row is the header, this tells SQL to start at the second row
			FIELDTERMINATOR = ',', --Tells SQL how each row is separated in file
			TABLOCK --Locks table while SQL is loading it. Improves performance
		);
		SET @end_time = GETDATE();
		PRINT '>> Load Duration: ' + CAST(DATEDIFF(second, @start_time,@end_time) AS NVARCHAR) + ' seconds';
		SET @batch_end_time =GETDATE();
		PRINT '***Total Load Duration: ' + CAST(DATEDIFF(second, @batch_start_time,@batch_end_time) AS NVARCHAR) + ' seconds***';
	END TRY
	BEGIN CATCH
		PRINT 'ERROR OCCURED DURING LOADING BRONZE LAYER'
		PRINT 'ERROR MESSAGE: ' + ERROR_MESSAGE();
		PRINT 'ERROR NUMBER: ' + CAST (ERROR_NUMBER() AS NVARCHAR);
	END CATCH
END

--TASK: Calculate the loading duration of the entire bronze layer
--SOLUTION: Declare variables to keep track of start and end time of entire batch and insert start at the 
--			beginning of try block and end at the end
