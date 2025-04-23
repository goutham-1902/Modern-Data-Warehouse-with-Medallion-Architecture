/*
===============================================================================
Stored Procedure: sp_test_silver
===============================================================================

Script Purpose:
    Runs data quality checks on the Silver layer to ensure:
        - Data integrity
        - Standardization
        - Logical consistency
        - Clean formatting

Usage:
    EXEC sp_test_silver;

Note:
    Any result returned from a check indicates a potential data issue.
===============================================================================
*/

USE data_warehouse_prj;
GO

CREATE OR ALTER PROCEDURE sp_test_silver AS
BEGIN
    SET NOCOUNT ON;

    PRINT '==================================================';
    PRINT 'Running Silver Layer Quality Checks...';
    PRINT '==================================================';

    -- ============================================================================
    -- 1. Checking Table: silver.crm_cust_info
    -- ============================================================================
    PRINT '>> Checking silver.crm_cust_info - Primary Key Validity (cst_id)';
    SELECT cst_id, COUNT(*) 
    FROM silver.crm_cust_info
    GROUP BY cst_id
    HAVING COUNT(*) > 1 OR cst_id IS NULL;

    PRINT '>> Checking silver.crm_cust_info - Trimmed Customer Keys';
    SELECT cst_key 
    FROM silver.crm_cust_info
    WHERE cst_key != TRIM(cst_key);

    PRINT '>> Checking silver.crm_cust_info - Marital Status Values';
    SELECT DISTINCT cst_marital_status 
    FROM silver.crm_cust_info;

    -- ============================================================================
    -- 2. Checking Table: silver.crm_prd_info
    -- ============================================================================
    PRINT '>> Checking silver.crm_prd_info - Primary Key Validity (prd_id)';
    SELECT prd_id, COUNT(*) 
    FROM silver.crm_prd_info
    GROUP BY prd_id
    HAVING COUNT(*) > 1 OR prd_id IS NULL;

    PRINT '>> Checking silver.crm_prd_info - Trimmed Product Names';
    SELECT prd_nm 
    FROM silver.crm_prd_info
    WHERE prd_nm != TRIM(prd_nm);

    PRINT '>> Checking silver.crm_prd_info - NULL or Negative Product Costs';
    SELECT prd_cost 
    FROM silver.crm_prd_info
    WHERE prd_cost < 0 OR prd_cost IS NULL;

    PRINT '>> Checking silver.crm_prd_info - Product Line Values';
    SELECT DISTINCT prd_line 
    FROM silver.crm_prd_info;

    PRINT '>> Checking silver.crm_prd_info - Invalid Date Ranges';
    SELECT * 
    FROM silver.crm_prd_info
    WHERE prd_end_dt < prd_start_dt;

    -- ============================================================================
    -- 3. Checking Table: silver.crm_sales_details
    -- ============================================================================
    PRINT '>> Checking bronze.crm_sales_details - Raw Invalid Dates';
    SELECT NULLIF(sls_due_dt, 0) AS sls_due_dt 
    FROM bronze.crm_sales_details
    WHERE sls_due_dt <= 0 
       OR LEN(sls_due_dt) != 8 
       OR sls_due_dt > 20500101 
       OR sls_due_dt < 19000101;

    PRINT '>> Checking silver.crm_sales_details - Date Logic (Order > Ship/Due)';
    SELECT * 
    FROM silver.crm_sales_details
    WHERE sls_order_dt > sls_ship_dt 
       OR sls_order_dt > sls_due_dt;

    PRINT '>> Checking silver.crm_sales_details - Sales ≠ Quantity * Price';
    SELECT DISTINCT sls_sales, sls_quantity, sls_price 
    FROM silver.crm_sales_details
    WHERE sls_sales != sls_quantity * sls_price
       OR sls_sales IS NULL 
       OR sls_quantity IS NULL 
       OR sls_price IS NULL
       OR sls_sales <= 0 
       OR sls_quantity <= 0 
       OR sls_price <= 0
    ORDER BY sls_sales, sls_quantity, sls_price;

    -- ============================================================================
    -- 4. Checking Table: silver.erp_cust_az12
    -- ============================================================================
    PRINT '>> Checking silver.erp_cust_az12 - Birthdate Range';
    SELECT DISTINCT bdate 
    FROM silver.erp_cust_az12
    WHERE bdate < '1924-01-01' 
       OR bdate > GETDATE();

    PRINT '>> Checking silver.erp_cust_az12 - Gender Values';
    SELECT DISTINCT gen 
    FROM silver.erp_cust_az12;

    -- ============================================================================
    -- 5. Checking Table: silver.erp_loc_a101
    -- ============================================================================
    PRINT '>> Checking silver.erp_loc_a101 - Country Values';
    SELECT DISTINCT cntry 
    FROM silver.erp_loc_a101
    ORDER BY cntry;

    -- ============================================================================
    -- 6. Checking Table: silver.erp_px_cat_g1v2
    -- ============================================================================
    PRINT '>> Checking silver.erp_px_cat_g1v2 - Trimmed Fields';
    SELECT * 
    FROM silver.erp_px_cat_g1v2
    WHERE cat != TRIM(cat) 
       OR subcat != TRIM(subcat) 
       OR maintenance != TRIM(maintenance);

    PRINT '>> Checking silver.erp_px_cat_g1v2 - Maintenance Value Distinct List';
    SELECT DISTINCT maintenance 
    FROM silver.erp_px_cat_g1v2;

    PRINT '==================================================';
    PRINT 'Silver Layer Checks Completed';
    PRINT '==================================================';
END;
GO