/*
===========================================
Creating Silver Tables inside the Database
===========================================

Script Purpose:
    This SQL script checks if the silver-layer tables already exist,
    drops them if they do (removing any data), and recreates them
    with the defined schema.

    It sets up 6 tables under the [silver] schema:

    -- A. CRM Tables
        1. silver.crm_cust_info
        2. silver.crm_prd_info
        3. silver.crm_sales_details

    -- B. ERP Tables
        4. silver.erp_cust_az12
        5. silver.erp_loc_a101
        6. silver.erp_px_cat_g1v2

Note:
    These tables often include a `dwh_create_date` column to track
    when records were inserted into the data warehouse layer.

Warning:
    Running this stored procedure will delete and recreate the tables.
    All existing data in these tables will be permanently lost.
*/

USE data_warehouse_prj;
GO

CREATE OR ALTER PROCEDURE sp_create_silver_tables
AS
BEGIN
    SET NOCOUNT ON;

    -- =====================================
    -- CRM Tables
    -- =====================================

    IF OBJECT_ID('silver.crm_cust_info', 'U') IS NOT NULL
        DROP TABLE silver.crm_cust_info;

    CREATE TABLE silver.crm_cust_info (
        cst_id             INT,
        cst_key            NVARCHAR(50),
        cst_firstname      NVARCHAR(50),
        cst_lastname       NVARCHAR(50),
        cst_marital_status NVARCHAR(50),
        cst_gndr           NVARCHAR(50),
        cst_create_date    DATE,
        dwh_create_date    DATETIME2 DEFAULT GETDATE()
    );

    IF OBJECT_ID('silver.crm_prd_info', 'U') IS NOT NULL
        DROP TABLE silver.crm_prd_info;

    CREATE TABLE silver.crm_prd_info (
        prd_id          INT,
        cat_id          NVARCHAR(50),
        prd_key         NVARCHAR(50),
        prd_nm          NVARCHAR(50),
        prd_cost        INT,
        prd_line        NVARCHAR(50),
        prd_start_dt    DATE,
        prd_end_dt      DATE,
        dwh_create_date DATETIME2 DEFAULT GETDATE()
    );

    IF OBJECT_ID('silver.crm_sales_details', 'U') IS NOT NULL
        DROP TABLE silver.crm_sales_details;

    CREATE TABLE silver.crm_sales_details (
        sls_ord_num     NVARCHAR(50),
        sls_prd_key     NVARCHAR(50),
        sls_cust_id     INT,
        sls_order_dt    DATE,
        sls_ship_dt     DATE,
        sls_due_dt      DATE,
        sls_sales       INT,
        sls_quantity    INT,
        sls_price       INT,
        dwh_create_date DATETIME2 DEFAULT GETDATE()
    );

    -- =====================================
    -- ERP Tables
    -- =====================================

    IF OBJECT_ID('silver.erp_loc_a101', 'U') IS NOT NULL
        DROP TABLE silver.erp_loc_a101;

    CREATE TABLE silver.erp_loc_a101 (
        cid             NVARCHAR(50),
        cntry           NVARCHAR(50),
        dwh_create_date DATETIME2 DEFAULT GETDATE()
    );

    IF OBJECT_ID('silver.erp_cust_az12', 'U') IS NOT NULL
        DROP TABLE silver.erp_cust_az12;

    CREATE TABLE silver.erp_cust_az12 (
        cid             NVARCHAR(50),
        bdate           DATE,
        gen             NVARCHAR(50),
        dwh_create_date DATETIME2 DEFAULT GETDATE()
    );

    IF OBJECT_ID('silver.erp_px_cat_g1v2', 'U') IS NOT NULL
        DROP TABLE silver.erp_px_cat_g1v2;

    CREATE TABLE silver.erp_px_cat_g1v2 (
        id              NVARCHAR(50),
        cat             NVARCHAR(50),
        subcat          NVARCHAR(50),
        maintenance     NVARCHAR(50),
        dwh_create_date DATETIME2 DEFAULT GETDATE()
    );
END;
GO