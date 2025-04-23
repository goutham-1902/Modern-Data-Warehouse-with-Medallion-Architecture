/*
===============================================================================
Stored Procedure: sp_test_gold
===============================================================================

Script Purpose:
    Performs data quality validation checks on the Gold Layer views.
    Ensures:
        - Surrogate key uniqueness in dimension views
        - Referential integrity between fact and dimension views
        - No disconnected records in the star schema

Usage:
    EXEC sp_test_gold;

Note:
    Any returned rows indicate potential data quality issues.
===============================================================================
*/

USE data_warehouse_prj;
GO

CREATE OR ALTER PROCEDURE sp_test_gold AS
BEGIN
    SET NOCOUNT ON;

    PRINT '==================================================';
    PRINT 'Running Gold Layer Quality Checks...';
    PRINT '==================================================';

    -- ============================================================================
    -- 1. Check Uniqueness in gold.dim_customers
    -- ============================================================================
    PRINT '>> Checking gold.dim_customers - Unique customer_key';
    SELECT 
        customer_key,
        COUNT(*) AS duplicate_count
    FROM gold.dim_customers
    GROUP BY customer_key
    HAVING COUNT(*) > 1;

    -- ============================================================================
    -- 2. Check Uniqueness in gold.dim_products
    -- ============================================================================
    PRINT '>> Checking gold.dim_products - Unique product_key';
    SELECT 
        product_key,
        COUNT(*) AS duplicate_count
    FROM gold.dim_products
    GROUP BY product_key
    HAVING COUNT(*) > 1;

    -- ============================================================================
    -- 3. Referential Integrity: fact_sales ↔ dim_customers/products
    -- ============================================================================
    PRINT '>> Checking gold.fact_sales - Referential Integrity to Dimensions';
    SELECT 
        f.* 
    FROM gold.fact_sales f
    LEFT JOIN gold.dim_customers c
        ON f.customer_key = c.customer_key
    LEFT JOIN gold.dim_products p
        ON f.product_key = p.product_key
    WHERE c.customer_key IS NULL 
       OR p.product_key IS NULL;

    PRINT '==================================================';
    PRINT 'Gold Layer Checks Completed';
    PRINT '==================================================';
END;
GO