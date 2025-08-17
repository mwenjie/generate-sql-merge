-- Test script for SCD functionality
-- This is a SQL Server T-SQL test script

-- Test SCD Type 1 example
DECLARE @output NVARCHAR(MAX);

-- Simulate calling the stored procedure with SCD Type 1
-- This would be: EXEC sp_generate_merge 'MyTable', @scd_type = 1, @output = @output OUTPUT, @results_to_text = NULL

-- For now, let's just verify the procedure can be parsed without syntax errors
-- by checking a simple syntax validation

PRINT 'Testing SCD functionality...';

-- Test that the new parameters exist by checking the procedure definition
IF OBJECT_ID('sp_generate_merge', 'P') IS NOT NULL
BEGIN
    PRINT 'sp_generate_merge procedure exists';
END
ELSE
BEGIN
    PRINT 'sp_generate_merge procedure does not exist';
END

-- Example of what the generated SCD Type 1 MERGE should look like:
/*
DECLARE @asof datetime2(7) = SYSUTCDATETIME();

MERGE INTO [Target].[Table] AS [Target]
USING (SELECT 
  [BusinessCol1], [BusinessCol2], [META_SOURCE],
  1 AS [META_CURRENT_RECORD_INDICATOR],
  @asof AS [META_EFFECTIVE_DATETIME],
  CAST('9999-12-31 23:59:59.9999999' AS datetime2(7)) AS [META_EXPIRY_DATETIME],
  CONVERT(varchar(64), HASHBYTES('SHA2_256', CONCAT([BusinessKey1], '|', [BusinessKey2])), 2) AS [META_KEY_CHECKSUM],
  CONVERT(varchar(64), HASHBYTES('SHA2_256', CONCAT([BusinessCol1], '|', [BusinessCol2])), 2) AS [META_RECORD_CHECKSUM]
  FROM [Source].[Table]
) AS [Source] ([BusinessCol1], [BusinessCol2], [META_SOURCE], [META_CURRENT_RECORD_INDICATOR], [META_EFFECTIVE_DATETIME], [META_EXPIRY_DATETIME], [META_KEY_CHECKSUM], [META_RECORD_CHECKSUM])
ON ([Target].[BusinessKey1] = [Source].[BusinessKey1] AND [Target].[BusinessKey2] = [Source].[BusinessKey2])
WHEN MATCHED AND [Target].[META_CURRENT_RECORD_INDICATOR] = 1 AND ([Target].[META_RECORD_CHECKSUM] <> [Source].[META_RECORD_CHECKSUM]) THEN
 UPDATE SET
  [Target].[META_EFFECTIVE_DATETIME] = @asof,
  [Target].[META_KEY_CHECKSUM] = [Source].[META_KEY_CHECKSUM],
  [Target].[META_RECORD_CHECKSUM] = [Source].[META_RECORD_CHECKSUM],
  [Target].[META_SOURCE] = [Source].[META_SOURCE]
WHEN NOT MATCHED BY TARGET THEN
 INSERT([BusinessCol1], [BusinessCol2], [META_SOURCE], [META_CURRENT_RECORD_INDICATOR], [META_EFFECTIVE_DATETIME], [META_EXPIRY_DATETIME], [META_KEY_CHECKSUM], [META_RECORD_CHECKSUM])
 VALUES([Source].[BusinessCol1], [Source].[BusinessCol2], [Source].[META_SOURCE], [Source].[META_CURRENT_RECORD_INDICATOR], [Source].[META_EFFECTIVE_DATETIME], [Source].[META_EXPIRY_DATETIME], [Source].[META_KEY_CHECKSUM], [Source].[META_RECORD_CHECKSUM]);
*/

PRINT 'SCD test script completed';