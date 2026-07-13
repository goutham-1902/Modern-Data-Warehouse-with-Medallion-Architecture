/*
===============================================================================
Architecture Script: Create Warehouse DB and Schemas
===============================================================================

Purpose:
    Drops and recreates the data warehouse database, and sets up the bronze,
    silver, and gold schemas required for Medallion Architecture.

Warning:
    This will drop the entire database and all contained objects!
===============================================================================
*/

-- Step 1: Drop and Recreate Database
USE master;
GO

IF EXISTS (
    SELECT 1 FROM sys.databases WHERE name = 'data_warehouse_prj'
)
BEGIN
    ALTER DATABASE data_warehouse_prj SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE data_warehouse_prj;
END;
GO

CREATE DATABASE data_warehouse_prj;
GO

-- Step 2: Use the new database
USE data_warehouse_prj;
GO

-- Step 3: Create Schemas (if not exists)
IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'bronze')
    EXEC('CREATE SCHEMA bronze');
GO

IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'silver')
    EXEC('CREATE SCHEMA silver');
GO

IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'gold')
    EXEC('CREATE SCHEMA gold');
GO

PRINT 'Database and schemas created successfully.';