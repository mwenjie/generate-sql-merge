-- Test script to reproduce the SCD qualifier bug
-- This creates a minimal test case to show the repeated [Source].[Source] qualifiers

USE tempdb;
GO

-- Create test tables
IF OBJECT_ID('tempdb..SourceTable', 'U') IS NOT NULL DROP TABLE SourceTable;
IF OBJECT_ID('tempdb..TargetTable', 'U') IS NOT NULL DROP TABLE TargetTable;

CREATE TABLE SourceTable (
    CustomerID INT,
    CustomerName VARCHAR(100),
    Email VARCHAR(100),
    META_SOURCE VARCHAR(50)
);

CREATE TABLE TargetTable (
    CustomerID INT,
    CustomerName VARCHAR(100), 
    Email VARCHAR(100),
    META_CURRENT_RECORD_INDICATOR BIT,
    META_EFFECTIVE_DATETIME DATETIME2(7),
    META_EXPIRY_DATETIME DATETIME2(7),
    META_KEY_CHECKSUM VARCHAR(64),
    META_RECORD_CHECKSUM VARCHAR(64),
    META_SOURCE VARCHAR(50)
);

INSERT INTO SourceTable VALUES (1, 'John Doe', 'john@example.com', 'TEST_SYSTEM');

-- Generate MERGE with SCD Type 1 to see the bug
DECLARE @output NVARCHAR(MAX);
EXEC sp_generate_merge 
    @table_name = 'SourceTable',
    @target_table = 'TargetTable',
    @scd_type = 1,
    @include_values = 1,
    @results_to_text = 1,
    @output = @output OUTPUT;

-- Look for [Source].[Source] patterns in the output
IF CHARINDEX('[Source].[Source]', @output) > 0
BEGIN
    PRINT 'BUG DETECTED: Found repeated [Source].[Source] qualifiers';
    PRINT 'Location: ' + CAST(CHARINDEX('[Source].[Source]', @output) AS VARCHAR(10));
END
ELSE
BEGIN
    PRINT 'No repeated qualifiers found';
END

-- Clean up
DROP TABLE SourceTable;
DROP TABLE TargetTable;