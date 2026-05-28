/*
===============================================================================
Stored Procedure: dbo.proc_load_bronze_table
Purpose:
    Generic metadata-driven ETL procedure used to load data from the
    AdventureWorks2025 OLTP source database into bronze-layer tables
    inside the AdventureWorks2025_CustomerDW warehouse.

Loading Strategy:
    - Full refresh load
    - Destination bronze table is truncated before reload
    - Source rows are reinserted with ETL audit timestamp

Architecture Notes:
    - Designed to work with the dbo.etl_bronze_table_mapping control table
    - Uses dynamic SQL to support reusable multi-table loading
    - Supports metadata-driven orchestration (SSIS / ADF / SQL Agent)

TARGET: SQL Server (AdventureWorks2025_CustomerDW) | AUTHOR: Amr Bayomei Basha | DATE: May 2026
VERSION: 1.0
===============================================================================
*/

USE [AdventureWorks2025_CustomerDW];
GO

/*
NOTE:
SET ANSI_NULLS ON enforces ANSI-standard NULL behavior.

With ANSI_NULLS ON:
    - Comparisons like column = NULL will NOT work
    - Proper syntax requires:
            column IS NULL
            column IS NOT NULL

Modern SQL Server features and indexed objects expect this setting ON.
*/
SET ANSI_NULLS ON;
GO

/*
NOTE:
SET QUOTED_IDENTIFIER ON controls how SQL Server interprets double quotes.

With QUOTED_IDENTIFIER ON:
    - Double quotes (" ") are treated as object identifiers
    - Single quotes (' ') are treated as string literals

This is the modern SQL Server standard behavior and is required
for several advanced SQL Server features.
*/
SET QUOTED_IDENTIFIER ON;
GO

/*
===============================================================================
Procedure Definition
===============================================================================
*/

ALTER PROCEDURE [dbo].[proc_load_bronze_table]

    -- Source OLTP schema name
    @source_schema NVARCHAR(128),

    -- Source OLTP table name
    @source_table NVARCHAR(128),

    -- Destination DW schema name
    @dest_schema NVARCHAR(128),

    -- Destination DW bronze table name
    @dest_table NVARCHAR(128)

AS
BEGIN

    /*
    NOTE:
    SET NOCOUNT ON suppresses:
            (xxx rows affected)

    messages after each statement execution.

    Benefits:
        - Reduces unnecessary network traffic
        - Improves ETL/procedure execution efficiency
        - Prevents interference with SSIS/orchestration logging
    */
    SET NOCOUNT ON;

    /*
    ===========================================================================
    STEP 1: Truncate destination bronze table
    ===========================================================================
    */

    DECLARE @sql NVARCHAR(MAX);

    /*
    NOTE:
    Dynamic SQL is required because table names are parameterized.
    SQL Server does not allow object names (tables/schemas)
    to be passed directly as parameters in static SQL.
    */

    SET @sql =
        N'TRUNCATE TABLE '
        + QUOTENAME(@dest_schema)
        + N'.'
        + QUOTENAME(@dest_table);

    /*
    NOTE:
    sp_executesql is preferred over EXEC() because:
        - Better practice for dynamic SQL
        - Supports parameterization
        - Better execution plan reuse
        - Cleaner and safer execution
    */
    EXEC sp_executesql @sql;

    /*
    ===========================================================================
    STEP 2: Load source data into bronze table
    ===========================================================================
    */

    SET @sql = N'
        INSERT INTO '
        + QUOTENAME(@dest_schema)
        + N'.'
        + QUOTENAME(@dest_table)
        + N'

        SELECT *,
               SYSUTCDATETIME() AS dwh_load_date

        FROM [AdventureWorks2025].'
        + QUOTENAME(@source_schema)
        + N'.'
        + QUOTENAME(@source_table);

    /*
    NOTE:
    SYSUTCDATETIME() is used instead of GETDATE() because:
        - UTC timestamps are timezone-independent
        - Better for distributed/cloud ETL systems
        - Improves audit consistency
    */

    EXEC sp_executesql @sql;

    /*
    ===========================================================================
    STEP 3: Print ETL execution message
    ===========================================================================
    */

    DECLARE @msg NVARCHAR(500);

    SET @msg =
        N'Loaded '
        + @source_schema
        + N'.'
        + @source_table
        + N' into '
        + @dest_schema
        + N'.'
        + @dest_table;

    PRINT @msg;

END;
GO
