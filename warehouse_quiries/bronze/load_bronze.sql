/*
================================
Loading Bronze Layer into Tables
================================

Script Purpose:
    Loads data into the bronze layer tables from CSV files using a helper procedure.
    This modular version makes the code cleaner and avoids repetition.

    It performs the following:
    - Defines a helper procedure to truncate and bulk insert a single table.
    - Calls that helper 6 times for 6 tables.

Tables Loaded:
    A. CRM
        1. bronze.crm_cust_info
        2. bronze.crm_prd_info
        3. bronze.crm_sales_details

    B. ERP
        4. bronze.erp_cust_az12
        5. bronze.erp_loc_a101
        6. bronze.erp_px_cat_g1v2

Warning:
    All existing data will be truncated. Ensure CSV paths are valid and container is correctly mounted.

Usage:
    EXEC bronze.load_bronze;
*/

USE data_warehouse_prj;
GO

-- ================================================
-- Step 1: Create helper procedure to load one table
-- ================================================
CREATE OR ALTER PROCEDURE bronze.load_single_table
    @table_name NVARCHAR(200),
    @file_path NVARCHAR(4000)
AS
BEGIN
    DECLARE @sql NVARCHAR(MAX)

    SET @sql = '
    PRINT ''------------------------------------------------'';
    PRINT ''Truncating and Loading: ' + @table_name + ''';

    TRUNCATE TABLE ' + @table_name + ';

    BULK INSERT ' + @table_name + '
    FROM ''' + @file_path + '''
    WITH (
        FIRSTROW = 2,
        FIELDTERMINATOR = '','',
        TABLOCK
    );

    PRINT ''Done loading: ' + @table_name + ''';
    '

    EXEC sp_executesql @sql;
END;
GO

-- ================================================
-- Step 2: Main loader procedure for bronze layer
-- ================================================
CREATE OR ALTER PROCEDURE bronze.load_bronze AS
BEGIN
    DECLARE @start DATETIME = GETDATE();

    PRINT '============================================';
    PRINT 'Loading Bronze Layer Started';
    PRINT '============================================';

    -- CRM tables
    EXEC bronze.load_single_table 'bronze.crm_cust_info', '/DWDM_Prj/datasets/source_crm/cust_info.csv';
    EXEC bronze.load_single_table 'bronze.crm_prd_info', '/DWDM_Prj/datasets/source_crm/prd_info.csv';
    EXEC bronze.load_single_table 'bronze.crm_sales_details', '/DWDM_Prj/datasets/source_crm/sales_details.csv';

    -- ERP tables
    EXEC bronze.load_single_table 'bronze.erp_cust_az12', '/DWDM_Prj/datasets/source_erp/CUST_AZ12.csv';
    EXEC bronze.load_single_table 'bronze.erp_loc_a101', '/DWDM_Prj/datasets/source_erp/LOC_A101.csv';
    EXEC bronze.load_single_table 'bronze.erp_px_cat_g1v2', '/DWDM_Prj/datasets/source_erp/PX_CAT_G1V2.csv';

    PRINT '============================================';
    PRINT 'Bronze Layer Load Complete';
    PRINT 'Total Load Duration (s): ' + CAST(DATEDIFF(SECOND, @start, GETDATE()) AS NVARCHAR);
    PRINT '============================================';
END;
GO