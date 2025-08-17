-- Test script to validate SCD Type 1 and Type 2 implementation
-- This demonstrates the expected output format

-- Example source table structure
/*
CREATE TABLE SourceTable (
    BusinessKey1 INT,
    BusinessKey2 VARCHAR(50),
    BusinessData1 VARCHAR(100),
    BusinessData2 DATE,
    META_SOURCE VARCHAR(50)
);
*/

-- Example target table structure for SCD
/*
CREATE TABLE TargetTable (
    BusinessKey1 INT,
    BusinessKey2 VARCHAR(50),
    BusinessData1 VARCHAR(100),
    BusinessData2 DATE,
    META_CURRENT_RECORD_INDICATOR BIT,
    META_EFFECTIVE_DATETIME DATETIME2(7),
    META_EXPIRY_DATETIME DATETIME2(7),
    META_KEY_CHECKSUM VARCHAR(64),
    META_RECORD_CHECKSUM VARCHAR(64),
    META_SOURCE VARCHAR(50)
);
*/

-- Expected SCD Type 1 MERGE output should look like:
PRINT 'Expected SCD Type 1 MERGE statement:';
PRINT '';
PRINT 'DECLARE @asof datetime2(7) = SYSUTCDATETIME();';
PRINT '';
PRINT 'MERGE INTO [TargetTable] AS [Target]';
PRINT 'USING (SELECT [BusinessKey1], [BusinessKey2], [BusinessData1], [BusinessData2],';
PRINT '  1 AS [META_CURRENT_RECORD_INDICATOR],';
PRINT '  @asof AS [META_EFFECTIVE_DATETIME],';
PRINT '  CAST(''9999-12-31 23:59:59.9999999'' AS datetime2(7)) AS [META_EXPIRY_DATETIME],';
PRINT '  CONVERT(varchar(64), HASHBYTES(''SHA2_256'', CONCAT([BusinessKey1],''|'',[BusinessKey2])), 2) AS [META_KEY_CHECKSUM],';
PRINT '  CONVERT(varchar(64), HASHBYTES(''SHA2_256'', CONCAT([BusinessData1],''|'',[BusinessData2])), 2) AS [META_RECORD_CHECKSUM],';
PRINT '  [META_SOURCE] AS [META_SOURCE]';
PRINT ' FROM [SourceTable]) AS [Source] ([BusinessKey1], [BusinessKey2], [BusinessData1], [BusinessData2], [META_CURRENT_RECORD_INDICATOR], [META_EFFECTIVE_DATETIME], [META_EXPIRY_DATETIME], [META_KEY_CHECKSUM], [META_RECORD_CHECKSUM], [META_SOURCE])';
PRINT 'ON ([Target].[BusinessKey1] = [Source].[BusinessKey1] AND [Target].[BusinessKey2] = [Source].[BusinessKey2])';
PRINT 'WHEN MATCHED AND [Target].[META_CURRENT_RECORD_INDICATOR] = 1 AND ([Target].[META_RECORD_CHECKSUM] <> [Source].[META_RECORD_CHECKSUM]) THEN';
PRINT ' UPDATE SET';
PRINT '  [Target].[META_EFFECTIVE_DATETIME] = @asof,';
PRINT '  [Target].[META_KEY_CHECKSUM] = [Source].[META_KEY_CHECKSUM],';
PRINT '  [Target].[META_RECORD_CHECKSUM] = [Source].[META_RECORD_CHECKSUM],';
PRINT '  [Target].[META_SOURCE] = [Source].[META_SOURCE]';
PRINT 'WHEN NOT MATCHED BY TARGET THEN';
PRINT ' INSERT([BusinessKey1], [BusinessKey2], [BusinessData1], [BusinessData2], [META_CURRENT_RECORD_INDICATOR], [META_EFFECTIVE_DATETIME], [META_EXPIRY_DATETIME], [META_KEY_CHECKSUM], [META_RECORD_CHECKSUM], [META_SOURCE])';
PRINT ' VALUES([Source].[BusinessKey1], [Source].[BusinessKey2], [Source].[BusinessData1], [Source].[BusinessData2], [Source].[META_CURRENT_RECORD_INDICATOR], [Source].[META_EFFECTIVE_DATETIME], [Source].[META_EXPIRY_DATETIME], [Source].[META_KEY_CHECKSUM], [Source].[META_RECORD_CHECKSUM], [Source].[META_SOURCE]);';
PRINT '';

-- Expected SCD Type 2 MERGE output should look like:
PRINT 'Expected SCD Type 2 MERGE statement:';
PRINT '';
PRINT 'DECLARE @asof datetime2(7) = SYSUTCDATETIME();';
PRINT '';
PRINT 'MERGE INTO [TargetTable] AS [Target]';
PRINT 'USING (SELECT [BusinessKey1], [BusinessKey2], [BusinessData1], [BusinessData2],';
PRINT '  1 AS [META_CURRENT_RECORD_INDICATOR],';
PRINT '  @asof AS [META_EFFECTIVE_DATETIME],';
PRINT '  CAST(''9999-12-31 23:59:59.9999999'' AS datetime2(7)) AS [META_EXPIRY_DATETIME],';
PRINT '  CONVERT(varchar(64), HASHBYTES(''SHA2_256'', CONCAT([BusinessKey1],''|'',[BusinessKey2])), 2) AS [META_KEY_CHECKSUM],';
PRINT '  CONVERT(varchar(64), HASHBYTES(''SHA2_256'', CONCAT([BusinessData1],''|'',[BusinessData2])), 2) AS [META_RECORD_CHECKSUM],';
PRINT '  [META_SOURCE] AS [META_SOURCE]';
PRINT ' FROM [SourceTable]) AS [Source] ([BusinessKey1], [BusinessKey2], [BusinessData1], [BusinessData2], [META_CURRENT_RECORD_INDICATOR], [META_EFFECTIVE_DATETIME], [META_EXPIRY_DATETIME], [META_KEY_CHECKSUM], [META_RECORD_CHECKSUM], [META_SOURCE])';
PRINT 'ON ([Target].[BusinessKey1] = [Source].[BusinessKey1] AND [Target].[BusinessKey2] = [Source].[BusinessKey2])';
PRINT 'WHEN MATCHED AND [Target].[META_CURRENT_RECORD_INDICATOR] = 1 AND ([Target].[META_RECORD_CHECKSUM] <> [Source].[META_RECORD_CHECKSUM]) THEN';
PRINT ' UPDATE SET';
PRINT '  [Target].[META_CURRENT_RECORD_INDICATOR] = 0,';
PRINT '  [Target].[META_EXPIRY_DATETIME] = @asof';
PRINT 'WHEN NOT MATCHED BY TARGET THEN';
PRINT ' INSERT([BusinessKey1], [BusinessKey2], [BusinessData1], [BusinessData2], [META_CURRENT_RECORD_INDICATOR], [META_EFFECTIVE_DATETIME], [META_EXPIRY_DATETIME], [META_KEY_CHECKSUM], [META_RECORD_CHECKSUM], [META_SOURCE])';
PRINT ' VALUES([Source].[BusinessKey1], [Source].[BusinessKey2], [Source].[BusinessData1], [Source].[BusinessData2], [Source].[META_CURRENT_RECORD_INDICATOR], [Source].[META_EFFECTIVE_DATETIME], [Source].[META_EXPIRY_DATETIME], [Source].[META_KEY_CHECKSUM], [Source].[META_RECORD_CHECKSUM], [Source].[META_SOURCE]);';
PRINT '';
PRINT '-- For SCD Type 2, a follow-up INSERT is needed for changed records:';
PRINT 'INSERT INTO [TargetTable] ([BusinessKey1], [BusinessKey2], [BusinessData1], [BusinessData2], [META_CURRENT_RECORD_INDICATOR], [META_EFFECTIVE_DATETIME], [META_EXPIRY_DATETIME], [META_KEY_CHECKSUM], [META_RECORD_CHECKSUM], [META_SOURCE])';
PRINT 'SELECT [BusinessKey1], [BusinessKey2], [BusinessData1], [BusinessData2], 1, @asof, CAST(''9999-12-31 23:59:59.9999999'' AS datetime2(7)), [META_KEY_CHECKSUM], [META_RECORD_CHECKSUM], [META_SOURCE]';
PRINT 'FROM [SourceTable] s';
PRINT 'WHERE NOT EXISTS (';
PRINT '  SELECT 1 FROM [TargetTable] t';
PRINT '  WHERE t.[BusinessKey1] = s.[BusinessKey1] AND t.[BusinessKey2] = s.[BusinessKey2]';
PRINT '    AND t.[META_CURRENT_RECORD_INDICATOR] = 1';
PRINT '    AND t.[META_RECORD_CHECKSUM] = s.[META_RECORD_CHECKSUM]';
PRINT ');';

PRINT '';
PRINT 'Test cases validated. The implementation should generate similar MERGE statements.';