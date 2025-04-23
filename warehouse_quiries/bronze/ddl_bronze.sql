/*
================================
Creating Tables inside Database
================================

Script Purpose:
    This SQL script checks if tables exist, 
    and drops them if they do (removing all data). Then, it recreates the tables
    and sets up 6 tables: 
    -- A. CRM Tables
        1. bronze.crm_cust_info
        2. bronze.crm_prd_info
        3. bronze.crm_sales_details

    -- B. ERP Tables
        4. bronze.erp_cust_az12
        5. bronze.erp_loc_a101
        6. bronze.erp_px_cat_g1v2

Warning:
    Running this stored procedure will delete the tables if they already exist. 
    All data will be permanently lost. Proceed with caution.
*/

USE data_warehouse_prj;
GO

CREATE OR ALTER PROCEDURE sp_create_bronze_tables
AS
BEGIN
    SET NOCOUNT ON;

    /*
    ======================
    Creating CRM Tables
    ======================
    */

    IF OBJECT_ID('bronze.crm_cust_info', 'U') IS NOT NULL
        DROP TABLE bronze.crm_cust_info;

    CREATE TABLE bronze.crm_cust_info(
        cst_id              INT,
        cst_key             NVARCHAR(50),
        cst_firstname       NVARCHAR(50),
        cst_lastname        NVARCHAR(50),
        cst_marital_status  NVARCHAR(50),
        cst_gndr            NVARCHAR(50),
        cst_create_date     DATE
    );

    IF OBJECT_ID('bronze.crm_prd_info', 'U') IS NOT NULL
        DROP TABLE bronze.crm_prd_info;

    CREATE TABLE bronze.crm_prd_info(
        prd_id          INT,
        prd_key         NVARCHAR(50),
        prd_nm          NVARCHAR(50),
        prd_cost        INT,
        prd_line        NVARCHAR(50),
        prd_start_dt    DATETIME,
        prd_end_dt      DATETIME
    );

    IF OBJECT_ID('bronze.crm_sales_details', 'U') IS NOT NULL
        DROP TABLE bronze.crm_sales_details;

    CREATE TABLE bronze.crm_sales_details(
        sls_ord_num     NVARCHAR(50),
        sls_prd_key     NVARCHAR(50),
        sls_cust_id     INT,
        sls_order_dt    INT,
        sls_ship_dt     INT,
        sls_due_dt      INT,
        sls_sales       INT,
        sls_quantity    INT,
        sls_price       INT
    );

    /*
    ======================
    Creating ERP Tables
    ======================
    */

    IF OBJECT_ID('bronze.erp_cust_az12', 'U') IS NOT NULL
        DROP TABLE bronze.erp_cust_az12;

    CREATE TABLE bronze.erp_cust_az12(
        cid     NVARCHAR(50),
        bdate   DATE,
        gen     NVARCHAR(50)
    );

    IF OBJECT_ID('bronze.erp_loc_a101', 'U') IS NOT NULL
        DROP TABLE bronze.erp_loc_a101;

    CREATE TABLE bronze.erp_loc_a101(
        cid     NVARCHAR(50),
        cntry   NVARCHAR(50)
    );

    IF OBJECT_ID('bronze.erp_px_cat_g1v2', 'U') IS NOT NULL
        DROP TABLE bronze.erp_px_cat_g1v2;

    CREATE TABLE bronze.erp_px_cat_g1v2(
        id              NVARCHAR(50),
        cat             NVARCHAR(50),
        subcat          NVARCHAR(50),
        maintenance     NVARCHAR(50)
    );
END;
GO