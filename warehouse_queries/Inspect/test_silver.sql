/*
===============================================================================
Stored Procedure: sp_test_silver
===============================================================================

Returns one machine-readable result set. A zero in failed_rows means that the
check passed. Warning rows describe known incompleteness that does not break
referential integrity; error rows indicate broken warehouse invariants.
===============================================================================
*/

USE data_warehouse_prj;
GO

CREATE OR ALTER PROCEDURE sp_test_silver
AS
BEGIN
    SET NOCOUNT ON;

    CREATE TABLE #quality_checks (
        check_name  NVARCHAR(200) NOT NULL,
        severity    NVARCHAR(20)  NOT NULL,
        failed_rows BIGINT        NOT NULL
    );

    INSERT INTO #quality_checks
    SELECT 'crm_customer_key_null_or_duplicate', 'error', COUNT(*)
    FROM (
        SELECT cst_id
        FROM silver.crm_cust_info
        GROUP BY cst_id
        HAVING cst_id IS NULL OR COUNT(*) > 1
    ) AS failures;

    INSERT INTO #quality_checks
    SELECT 'crm_customer_key_whitespace', 'error', COUNT(*)
    FROM silver.crm_cust_info
    WHERE cst_key IS NULL OR cst_key <> TRIM(cst_key);

    INSERT INTO #quality_checks
    SELECT 'crm_customer_invalid_marital_status', 'error', COUNT(*)
    FROM silver.crm_cust_info
    WHERE cst_marital_status NOT IN ('Single', 'Married', 'n/a')
       OR cst_marital_status IS NULL;

    INSERT INTO #quality_checks
    SELECT 'crm_customer_unknown_gender', 'warning', COUNT(*)
    FROM silver.crm_cust_info
    WHERE cst_gndr = 'n/a' OR cst_gndr IS NULL;

    INSERT INTO #quality_checks
    SELECT 'crm_product_key_null_or_duplicate', 'error', COUNT(*)
    FROM (
        SELECT prd_id
        FROM silver.crm_prd_info
        GROUP BY prd_id
        HAVING prd_id IS NULL OR COUNT(*) > 1
    ) AS failures;

    INSERT INTO #quality_checks
    SELECT 'crm_product_unmatched_category', 'error', COUNT(*)
    FROM silver.crm_prd_info AS products
    LEFT JOIN silver.erp_px_cat_g1v2 AS categories
        ON products.cat_id = categories.id
    WHERE categories.id IS NULL;

    INSERT INTO #quality_checks
    SELECT 'crm_product_invalid_cost', 'error', COUNT(*)
    FROM silver.crm_prd_info
    WHERE prd_cost IS NULL OR prd_cost < 0;

    INSERT INTO #quality_checks
    SELECT 'crm_product_invalid_line', 'error', COUNT(*)
    FROM silver.crm_prd_info
    WHERE prd_line NOT IN ('Mountain', 'Road', 'Other Sales', 'Touring', 'n/a')
       OR prd_line IS NULL;

    INSERT INTO #quality_checks
    SELECT 'crm_product_invalid_date_range', 'error', COUNT(*)
    FROM silver.crm_prd_info
    WHERE prd_end_dt < prd_start_dt;

    INSERT INTO #quality_checks
    SELECT 'crm_sales_missing_order_date', 'warning', COUNT(*)
    FROM silver.crm_sales_details
    WHERE sls_order_dt IS NULL;

    INSERT INTO #quality_checks
    SELECT 'crm_sales_invalid_date_sequence', 'error', COUNT(*)
    FROM silver.crm_sales_details
    WHERE sls_order_dt > sls_ship_dt
       OR sls_order_dt > sls_due_dt
       OR sls_ship_dt > sls_due_dt;

    INSERT INTO #quality_checks
    SELECT 'crm_sales_invalid_measure', 'error', COUNT(*)
    FROM silver.crm_sales_details
    WHERE sls_sales IS NULL
       OR sls_quantity IS NULL
       OR sls_price IS NULL
       OR sls_sales <= 0
       OR sls_quantity <= 0
       OR sls_price <= 0
       OR sls_sales <> sls_quantity * sls_price;

    INSERT INTO #quality_checks
    SELECT 'erp_customer_implausible_birthdate', 'warning', COUNT(*)
    FROM silver.erp_cust_az12
    WHERE bdate < DATEADD(YEAR, -110, CAST(GETDATE() AS DATE))
       OR bdate > CAST(GETDATE() AS DATE);

    INSERT INTO #quality_checks
    SELECT 'erp_customer_unknown_gender', 'warning', COUNT(*)
    FROM silver.erp_cust_az12
    WHERE gen = 'n/a' OR gen IS NULL;

    INSERT INTO #quality_checks
    SELECT 'erp_location_unknown_country', 'warning', COUNT(*)
    FROM silver.erp_loc_a101
    WHERE cntry = 'n/a' OR cntry IS NULL;

    INSERT INTO #quality_checks
    SELECT 'erp_category_key_null_or_duplicate', 'error', COUNT(*)
    FROM (
        SELECT id
        FROM silver.erp_px_cat_g1v2
        GROUP BY id
        HAVING id IS NULL OR COUNT(*) > 1
    ) AS failures;

    INSERT INTO #quality_checks
    SELECT 'erp_category_invalid_maintenance_value', 'error', COUNT(*)
    FROM silver.erp_px_cat_g1v2
    WHERE maintenance NOT IN ('Yes', 'No') OR maintenance IS NULL;

    SELECT check_name, severity, failed_rows
    FROM #quality_checks
    ORDER BY
        CASE severity WHEN 'error' THEN 1 ELSE 2 END,
        check_name;
END;
GO
