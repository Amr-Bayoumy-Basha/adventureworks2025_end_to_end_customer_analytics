/*=================================================================================
Gold Layer - Populate Dim_Date
=================================================================================
Purpose: Generate date dimension data from 2010 to 2030
Includes: Calendar attributes, fiscal year, holidays

TARGET: SQL Server (AdventureWorks2025_CustomerDW) | AUTHOR: Amr Bayomei Basha | DATE: May 2026
VERSION: 1.0
=================================================================================
*/

USE AdventureWorks2025_CustomerDW;
GO

PRINT '=================================================================================';
PRINT 'Populating Gold Dim_Date (2010-2030)';
PRINT '=================================================================================';
PRINT '';

DECLARE @StartDate DATE = '2010-01-01';
DECLARE @EndDate DATE = '2030-12-31';
DECLARE @FiscalYearStartMonth INT = 7;  -- Fiscal year starts July 1st (adjust as needed)

-- Temporary table to generate date range
IF OBJECT_ID('tempdb..#DateSequence') IS NOT NULL DROP TABLE #DateSequence;

;WITH DateSequence AS (
    SELECT @StartDate AS DateValue
    UNION ALL
    SELECT DATEADD(DAY, 1, DateValue)
    FROM DateSequence
    WHERE DateValue < @EndDate
)
SELECT DateValue
INTO #DateSequence
FROM DateSequence
OPTION (MAXRECURSION 0);

-- Clear existing data
TRUNCATE TABLE gold.dim_date;

-- Insert date dimension data
INSERT INTO gold.dim_date (
    date_key,
    date,
    year,
    quarter,
    month,
    month_name,
    day_of_month,
    day_of_week,
    day_name,
    week_of_year,
    is_weekend,
    is_holiday,
    fiscal_year,
    fiscal_quarter,
    fiscal_month,
    year_month,
    quarter_name
)
SELECT
    -- Date key in YYYYMMDD format
    CAST(FORMAT(d.DateValue, 'yyyyMMdd') AS INT) AS date_key,
    
    -- Actual date
    d.DateValue AS date,
    
    -- Calendar year attributes
    YEAR(d.DateValue) AS year,
    DATEPART(QUARTER, d.DateValue) AS quarter,
    MONTH(d.DateValue) AS month,
    DATENAME(MONTH, d.DateValue) AS month_name,
    DAY(d.DateValue) AS day_of_month,
    
    -- Day of week (1=Monday, 7=Sunday per ISO 8601)
    CASE DATEPART(WEEKDAY, d.DateValue)
        WHEN 1 THEN 7  -- Sunday
        WHEN 2 THEN 1  -- Monday
        WHEN 3 THEN 2  -- Tuesday
        WHEN 4 THEN 3  -- Wednesday
        WHEN 5 THEN 4  -- Thursday
        WHEN 6 THEN 5  -- Friday
        WHEN 7 THEN 6  -- Saturday
    END AS day_of_week,
    
    DATENAME(WEEKDAY, d.DateValue) AS day_name,
    DATEPART(WEEK, d.DateValue) AS week_of_year,
    
    -- Weekend flag
    CASE WHEN DATEPART(WEEKDAY, d.DateValue) IN (1, 7) THEN 1 ELSE 0 END AS is_weekend,
    
    -- Holiday flag (US holidays as example - customize as needed)
    CASE
        -- New Year's Day
        WHEN MONTH(d.DateValue) = 1 AND DAY(d.DateValue) = 1 THEN 1
        -- Independence Day
        WHEN MONTH(d.DateValue) = 7 AND DAY(d.DateValue) = 4 THEN 1
        -- Christmas
        WHEN MONTH(d.DateValue) = 12 AND DAY(d.DateValue) = 25 THEN 1
        -- Thanksgiving (4th Thursday of November)
        WHEN MONTH(d.DateValue) = 11 
         AND DATENAME(WEEKDAY, d.DateValue) = 'Thursday'
         AND DAY(d.DateValue) BETWEEN 22 AND 28 THEN 1
        ELSE 0
    END AS is_holiday,
    
    -- Fiscal year (starts in July - month 7)
    CASE 
        WHEN MONTH(d.DateValue) >= @FiscalYearStartMonth 
        THEN YEAR(d.DateValue) + 1
        ELSE YEAR(d.DateValue)
    END AS fiscal_year,
    
    -- Fiscal quarter
    CASE 
        WHEN MONTH(d.DateValue) >= @FiscalYearStartMonth 
        THEN ((MONTH(d.DateValue) - @FiscalYearStartMonth) / 3) + 1
        ELSE ((MONTH(d.DateValue) + (12 - @FiscalYearStartMonth)) / 3) + 1
    END AS fiscal_quarter,
    
    -- Fiscal month
    CASE 
        WHEN MONTH(d.DateValue) >= @FiscalYearStartMonth 
        THEN MONTH(d.DateValue) - @FiscalYearStartMonth + 1
        ELSE MONTH(d.DateValue) + (12 - @FiscalYearStartMonth) + 1
    END AS fiscal_month,
    
    -- Year-Month (e.g., "2023-01")
    FORMAT(d.DateValue, 'yyyy-MM') AS year_month,
    
    -- Quarter name (e.g., "Q1 2023")
    'Q' + CAST(DATEPART(QUARTER, d.DateValue) AS VARCHAR(1)) + ' ' + 
    CAST(YEAR(d.DateValue) AS VARCHAR(4)) AS quarter_name

FROM #DateSequence d;

-- Cleanup
DROP TABLE #DateSequence;

-- Verification
DECLARE @RowCount INT;
SELECT @RowCount = COUNT(*) FROM gold.dim_date;

PRINT '';
PRINT '=================================================================================';
PRINT 'Date Dimension Population Complete';
PRINT '=================================================================================';
PRINT 'Total Rows Inserted: ' + CAST(@RowCount AS VARCHAR(10));
PRINT 'Date Range: 2010-01-01 to 2030-12-31';
PRINT 'Fiscal Year Start: July (Month ' + CAST(@FiscalYearStartMonth AS VARCHAR(2)) + ')';
PRINT '=================================================================================';
PRINT '';

-- Show sample data
PRINT 'Sample Data (First 10 rows of 2024):';
SELECT TOP 10
    date_key,
    date,
    day_name,
    year_month,
    quarter_name,
    fiscal_year,
    is_weekend,
    is_holiday
FROM gold.dim_date
WHERE year = 2024
ORDER BY date;

-- Summary statistics
PRINT '';
PRINT 'Summary Statistics:';
SELECT 
    'Total Days' AS metric,
    COUNT(*) AS value
FROM gold.dim_date
UNION ALL
SELECT 'Weekends', COUNT(*) FROM gold.dim_date WHERE is_weekend = 1
UNION ALL
SELECT 'Holidays', COUNT(*) FROM gold.dim_date WHERE is_holiday = 1
UNION ALL
SELECT 'Fiscal Years', COUNT(DISTINCT fiscal_year) FROM gold.dim_date;

GO

