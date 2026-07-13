USE data_warehouse_prj;
GO
SELECT 
    SCHEMA_NAME(schema_id) AS schema_name,
    name AS procedure_name
FROM sys.procedures
ORDER BY schema_name, name;