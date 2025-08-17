-- Test to verify basic syntax is correct
-- This script tests the core logic without actually running the stored procedure

-- Test the sanitize-then-qualify pattern from the fix
DECLARE @Column_List_Insert_Values NVARCHAR(MAX) = '[Source].[CustomerID],[CustomerName],[Source].[Email]'

-- Test the NOT MATCHED BY TARGET fix pattern
DECLARE @PayloadValues NVARCHAR(MAX) = @Column_List_Insert_Values
SET @PayloadValues = REPLACE(@PayloadValues, '[Target].[', '[')
SET @PayloadValues = REPLACE(@PayloadValues, '[Source].[', '[')
SET @PayloadValues = REPLACE(@PayloadValues, '[', '[Source].[')

SELECT 'NOT MATCHED BY TARGET Values Fix:' AS TestType,
       @Column_List_Insert_Values AS Original,
       @PayloadValues AS Fixed

-- Test the SCD Type 2 fix pattern  
DECLARE @Business_Column_List_Insert_Values NVARCHAR(MAX) = '[Source].[CustomerID],[CustomerName],[Target].[Email]'
DECLARE @SelectCols NVARCHAR(MAX) = @Business_Column_List_Insert_Values
SET @SelectCols = REPLACE(@SelectCols, '[S].[', '[')
SET @SelectCols = REPLACE(@SelectCols, '[Source].[', '[')
SET @SelectCols = REPLACE(@SelectCols, '[Target].[', '[')
SET @SelectCols = REPLACE(@SelectCols, '[', '[S].[')

SELECT 'SCD Type 2 SELECT Fix:' AS TestType,
       @Business_Column_List_Insert_Values AS Original,
       @SelectCols AS Fixed

-- Test META column presence check
DECLARE @Column_List NVARCHAR(MAX) = '[CustomerID],[CustomerName],[META_SOURCE]'
DECLARE @meta_current SYSNAME = 'META_CURRENT_RECORD_INDICATOR'
DECLARE @meta_source SYSNAME = 'META_SOURCE'

SELECT 'META Column Check:' AS TestType,
       CASE WHEN CHARINDEX(QUOTENAME(@meta_current), @Column_List) = 0 
            THEN 'META_CURRENT will be added'
            ELSE 'META_CURRENT already present'
       END AS CurrentCheck,
       CASE WHEN CHARINDEX(QUOTENAME(@meta_source), @Column_List) = 0
            THEN 'META_SOURCE will be added'  
            ELSE 'META_SOURCE already present'
       END AS SourceCheck