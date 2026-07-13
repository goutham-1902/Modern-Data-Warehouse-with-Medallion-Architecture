/*
===============================================================================
Stored Procedure: sp_test_gold
===============================================================================

Returns one machine-readable result set for dimension-key uniqueness, fact
referential integrity, required measures, date logic, and enrichment coverage.
===============================================================================
*/

USE data_warehouse_prj;
GO

CREATE OR ALTER PROCEDURE sp_test_gold
AS
BEGIN
    SET NOCOUNT ON;

    CREATE TABLE #quality_checks (
        check_name  NVARCHAR(200) NOT NULL,
        severity    NVARCHAR(20)  NOT NULL,
        failed_rows BIGINT        NOT NULL
    );

    INSERT INTO #quality_checks
    SELECT 'dim_customer_surrogate_key_null_or_duplicate', 'error', COUNT(*)
    FROM (
        SELECT customer_key
        FROM gold.dim_customers
        GROUP BY customer_key
        HAVING customer_key IS NULL OR COUNT(*) > 1
    ) AS failures;

    INSERT INTO #quality_checks
    SELECT 'dim_customer_natural_key_null_or_duplicate', 'error', COUNT(*)
    FROM (
        SELECT customer_id
        FROM gold.dim_customers
        GROUP BY customer_id
        HAVING customer_id IS NULL OR COUNT(*) > 1
    ) AS failures;

    INSERT INTO #quality_checks
    SELECT 'dim_customer_unknown_gender', 'warning', COUNT(*)
    FROM gold.dim_customers
    WHERE gender = 'n/a' OR gender IS NULL;

    INSERT INTO #quality_checks
    SELECT 'dim_customer_unknown_country', 'warning', COUNT(*)
    FROM gold.dim_customers
    WHERE country = 'n/a' OR country IS NULL;

    INSERT INTO #quality_checks
    SELECT 'dim_product_surrogate_key_null_or_duplicate', 'error', COUNT(*)
    FROM (
        SELECT product_key
        FROM gold.dim_products
        GROUP BY product_key
        HAVING product_key IS NULL OR COUNT(*) > 1
    ) AS failures;

    INSERT INTO #quality_checks
    SELECT 'dim_product_natural_key_null_or_duplicate', 'error', COUNT(*)
    FROM (
        SELECT product_number
        FROM gold.dim_products
        GROUP BY product_number
        HAVING product_number IS NULL OR COUNT(*) > 1
    ) AS failures;

    INSERT INTO #quality_checks
    SELECT 'dim_product_missing_category_enrichment', 'error', COUNT(*)
    FROM gold.dim_products
    WHERE category IS NULL OR subcategory IS NULL OR maintenance IS NULL;

    INSERT INTO #quality_checks
    SELECT 'fact_sales_missing_dimension_key', 'error', COUNT(*)
    FROM gold.fact_sales
    WHERE customer_key IS NULL OR product_key IS NULL;

    INSERT INTO #quality_checks
    SELECT 'fact_sales_orphan_dimension_key', 'error', COUNT(*)
    FROM gold.fact_sales AS facts
    LEFT JOIN gold.dim_customers AS customers
        ON facts.customer_key = customers.customer_key
    LEFT JOIN gold.dim_products AS products
        ON facts.product_key = products.product_key
    WHERE customers.customer_key IS NULL OR products.product_key IS NULL;

    INSERT INTO #quality_checks
    SELECT 'fact_sales_missing_order_date', 'warning', COUNT(*)
    FROM gold.fact_sales
    WHERE order_date IS NULL;

    INSERT INTO #quality_checks
    SELECT 'fact_sales_invalid_date_sequence', 'error', COUNT(*)
    FROM gold.fact_sales
    WHERE order_date > shipping_date
       OR order_date > due_date
       OR shipping_date > due_date;

    INSERT INTO #quality_checks
    SELECT 'fact_sales_invalid_measure', 'error', COUNT(*)
    FROM gold.fact_sales
    WHERE sales_amount IS NULL
       OR quantity IS NULL
       OR price IS NULL
       OR sales_amount <= 0
       OR quantity <= 0
       OR price <= 0
       OR sales_amount <> quantity * price;

    SELECT check_name, severity, failed_rows
    FROM #quality_checks
    ORDER BY
        CASE severity WHEN 'error' THEN 1 ELSE 2 END,
        check_name;
END;
GO
