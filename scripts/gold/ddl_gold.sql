/*
DDL Script: Create Gold Views

Script Purpose:
    This script creates views for the Gold layer in the data warehouse. 
    The Gold layer represents the final dimension and fact tables (Star Schema)

    Each view performs transformations and combines data from the Silver layer 
    to produce a clean, enriched, and business-ready dataset.

Usage:
    - These views can be queried directly for analytics and reporting.

*/

--CREATE DIMENSION CUSTOMERS 
--Take 3 customer tables and form one customer object
--Rename and reorder columns for better readability
IF OBJECT_ID('gold.dim_customers', 'V') IS NOT NULL
    DROP VIEW gold.dim_customers;
GO

CREATE VIEW gold.dim_customers AS 
SELECT
	ROW_NUMBER() OVER (ORDER BY cst_id) AS customer_key, --Surrogate key
	ci.cst_id AS customer_id,
	ci.cst_key AS customer_number,
	ci.cst_firstname AS first_name,
	ci.cst_lastname AS last_name,
	la.cntry AS country,
	ci.cst_marital_status AS marital_status,
	CASE 
		WHEN ci.cst_gndr != 'N/A' THEN ci.cst_gndr --CRM is master for gender info
		ELSE COALESCE(ca.gen, 'N/A') --If crm value is n/a then use erp value, if erp value is null then use n/a
	END AS gender,
	ca.bdate AS birthdate,
	ci.cst_create_date AS create_date
FROM silver.crm_cust_info ci
LEFT JOIN silver.erp_cust_az12 ca
	ON ci.cst_key = ca.cid
LEFT JOIN silver.erp_loc_a101 la
	ON ci.cst_key = la.cid

--TIP: After joining table, check if any duplicates were introduced by the join logic
/*
	SELECT cst_id, COUNT(*) FROM (
		SELECT
			ci.cst_id,
			ci.cst_key,
			ci.cst_firstname,
			ci.cst_lastname,
			ci.cst_marital_status,
			ci.cst_gndr,
			ci.cst_create_date,
			ca.bdate,
			ca.gen,
			la.cntry
		FROM silver.crm_cust_info ci
		LEFT JOIN silver.erp_cust_az12 ca
		ON ci.cst_key = ca.cid
		LEFT JOIN silver.erp_loc_a101 la
		ON ci.cst_key = la.cid) t 
	GROUP BY cst_id HAVING COUNT(*) > 1
*/

--CREATE DIMENSION PRODUCTS

IF OBJECT_ID('gold.dim_products', 'V') IS NOT NULL
    DROP VIEW gold.dim_products;
GO

CREATE VIEW gold.dim_products AS
SELECT
	ROW_NUMBER() OVER (ORDER BY pn.prd_start_dt, pn.prd_key) AS product_key,
	pn.prd_id AS product_id,
	pn.prd_key AS product_number,
	pn.prd_nm AS product_name,
	pn.cat_id AS category_id,
	px.cat AS category,
	px.subcat AS subcategory,
	px.maintenance,
	pn.prd_cost AS cost,
	pn.prd_line AS product_line,
	pn.prd_start_dt AS start_date	
FROM silver.crm_prd_info pn
LEFT JOIN silver.erp_px_cat_g1v2 px
	ON pn.cat_id = px.id
WHERE prd_end_dt IS NULL --filter out all historical data. null end date = live product


--CREATE FACT SALES
--Building fact: Use the dimension's surrogate keys instead of IDs to easily connect facts with dimensions
--Remove original product and customer key from source system and replace with surrogate keys
IF OBJECT_ID('gold.fact_sales', 'V') IS NOT NULL
    DROP VIEW gold.fact_sales;
GO

CREATE VIEW gold.fact_sales AS
SELECT
    sd.sls_ord_num AS order_number,
    pr.product_key AS product_key, --Surrogate key
    cu.customer_key AS customer_key, --Surrogate key
    sd.sls_order_dt AS order_date,
    sd.sls_ship_dt AS shipping_date,
    sd.sls_due_dt AS due_date,
    sd.sls_sales AS sales_amount,
    sd.sls_quantity AS quantity,
    sd.sls_price AS price
FROM silver.crm_sales_details sd
LEFT JOIN gold.dim_products pr
    ON sd.sls_prd_key = pr.product_number
LEFT JOIN gold.dim_customers cu
    ON sd.sls_cust_id = cu.customer_id;


/*
	CHECK FK INTERGRITY (Dimensions)
	Expectation: empty result set

	SELECT *
	FROM gold.fact_sales f
	LEFT JOIN gold.dim_customers c
	ON c.customer_key = f.customer key
	LEFT JOIN gold.dim_products p
	ON p.product_key = f.product_key
	WHERE p.product_key IS NULL
*/
