
/*
===============================================================================
Quality Checks
===============================================================================
Script Purpose:
    This script performs various quality checks for data consistency, accuracy, 
    and standardization across the 'silver' layer. It includes checks for:
    - Null or duplicate primary keys.
    - Unwanted spaces in string fields.
    - Data standardization and consistency.
    - Invalid date ranges and orders.
    - Data consistency between related fields.

Usage Notes:
    - Run these checks after data loading Silver Layer.
    - Investigate and resolve any discrepancies found during the checks.
===============================================================================
*/

/* ===============================================================================
   ============================ Let's Begin ======================================
*/


/*
Check for NULLS OR DUPLICATES in primary key
EXPECTATIONS: NO Result
*/

SELECT 
prd_id,
count(*)
FROM bronze.crm_prd_info
GROUP BY prd_id
HAVING COUNT(*)>1 OR prd_id IS NULL;

-- Check for unwanted spece
-- Expectations: NO Result
SELECT
COUNT(*)
FROM silver.crm_cust_info
WHERE LEN(cst_firstname)!=LEN(TRIM(cst_firstname));

SELECT 
    * 
FROM silver.erp_px_cat_g1v2
WHERE cat != TRIM(cat) 
   OR subcat != TRIM(subcat) 
   OR maintenance != TRIM(maintenance);

--Data standarization & consistency
SELECT 
DISTINCT prd_line
FROM bronze.crm_prd_info;

SELECT 
DISTINCT cntry
FROM bronze.erp_loc_a101;

/* Explanation:
ISDATE() returns 1 if the value can be converted to a valid date.
Returns 0 if it can’t (e.g., 'abc', '32-15-2024', '2024-13-01', etc.)
The AND cst_create_date IS NOT NULL excludes blank or null values.*/

SELECT *
FROM bronze.crm_cust_info
WHERE ISDATE(cst_create_date) = 0
      AND cst_create_date IS NOT NULL;

/* Check for null or negative numbers in a integer value colums
	Expectations : No Results*/

select prd_cost
from bronze.crm_prd_info
where prd_cost<0 or prd_cost is null;

/* Check for invlid date orders if there are multiple date columns
	Expectations : No Results*/

select *
from bronze.crm_prd_info
where prd_end_dt<prd_start_dt;

SELECT *
FROM bronze.crm_sales_details
WHERE sls_order_dt>sls_ship_dt OR sls_order_dt>sls_due_dt; -- SALES_DETAILS TABLE

/* Check for valid date columns
	Expectations : No Results*/

SELECT sls_order_dt
FROM bronze.crm_sales_details
WHERE sls_order_dt<0 --ANY NEGATIVE VALUE
OR sls_order_dt=0	-- ANY VALUE EQUALS TO ZERO
OR sls_order_dt IS NULL 
OR LEN(sls_order_dt)!=8
OR sls_order_dt<19000101 --LESS THEN MINIMUM DATE
OR sls_order_dt>30500101 -- GREATER THEN MAXIMUM DATE
;

/* Check for DATA CONSISTENCY: among sales, quantity and price
	sales : quantity*price
	Expectations :values must not be null, zero and negative*/

SELECT DISTINCT
sls_sales,
sls_quantity,
sls_price
FROM bronze.crm_sales_details
WHERE sls_sales!=sls_quantity*sls_price
OR sls_sales IS NULL OR sls_quantity IS NULL OR sls_price IS NULL
OR sls_sales<=0 OR sls_quantity<=0 OR sls_price<=0
ORDER BY sls_sales,
sls_quantity,
sls_price;

/* Check for data simillarities
	*/

SELECT 
	cid,
	bdate,
	gen
FROM bronze.erp_cust_az12
WHERE cid LIKE '%AW00011000%';-- WE ARE GETTING 'NAS' IN FRONT OF VALUES, we need onlu AW00011000

/* Check for OUT OF RANGE DATES
	EXpectations: NO Result*/
SELECT 
	cid,
	bdate,
	gen
FROM bronze.erp_cust_az12
where bdate>getdate() or bdate<'1924-01-01';--checking whether the value is greater than today value or smaller then minimum


