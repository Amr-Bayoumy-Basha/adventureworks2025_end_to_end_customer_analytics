/*
- This script creates the DataWarehouse database only if it doesn't already exist.
- Creates bronze / silver / gold schemas only if they don't already exist.
- Safe for use in dev: no drops, no roles, no advanced settings
Run this on a SQL Server instance with a login that can create databases.

TARGET: SQL Server (AdventureWorks2025_customerDW) | 
AUTHOR: Amr Bayomei Basha | DATE: May 2026
*/

USE master;
GO

-- Create the AdventureWorks2025_CustomerDW database if it doesn't exist
IF DB_ID(N'AdventureWorks2025_CustomerDW') IS NULL
BEGIN
	PRINT 'Creating database AdventureWorks2025_CustomerDW...';
	CREATE DATABASE AdventureWorks2025_CustomerDW;
	PRINT 'Database AdventureWorks2025_CustomerDW created successfully.';
END
ELSE
BEGIN
	PRINT 'Database AdventureWorks2025_CustomerDW already exists. Skipping creation.';
END
GO

USE AdventureWorks2025_CustomerDW;
GO

-- Create schemas if they do not exist
IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = N'bronze')
BEGIN
	PRINT 'Creating schema bronze...';
	EXEC('CREATE SCHEMA bronze');
	PRINT 'Schema bronze created successfully.';
END
ELSE
	PRINT 'Schema bronze already exists. Skipping creation.';

IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = N'silver')
BEGIN
	PRINT 'Creating schema silver...';
	EXEC('CREATE SCHEMA silver');
	PRINT 'Schema silver created successfully.';
END
ELSE
	PRINT 'Schema silver already exists. Skipping creation.';

IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = N'gold')
BEGIN
	PRINT 'Creating schema gold...';
	EXEC('CREATE SCHEMA gold');
	PRINT 'Schema gold created successfully.';
END
ELSE
	PRINT 'Schema gold already exists. Skipping creation.';

GO

PRINT 'Done. Your DataWarehouse database with bronze/silver/gold schemas is ready.';


-- STUDY NOTE:
-- Schemas are checked using sys.schemas (or SCHEMA_ID()) instead of OBJECT_ID()
-- because schemas are stored as metadata objects, not regular schema-scoped objects
-- like tables or views. OBJECT_ID(...,'S') is not intended for schema validation.

-- NOTE:
-- CREATE SCHEMA is executed using dynamic SQL through EXEC()
-- to avoid SQL Server batch parsing/compilation restrictions with certain DDL statements.
-- EXEC() delays execution until runtime, making conditional deployment scripts safer and reusable.