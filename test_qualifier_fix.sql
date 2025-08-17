-- Test script to validate the qualifier fixes
-- This tests that the sanitize-then-qualify logic works correctly

-- Test 1: Check that repeated qualifiers are fixed
DECLARE @Column_List_Insert_Values NVARCHAR(MAX) = '[Source].[Col1],[Target].[Col2],[Col3]'
DECLARE @PayloadValues NVARCHAR(MAX) = @Column_List_Insert_Values

-- Apply sanitize-then-qualify pattern
SET @PayloadValues = REPLACE(@PayloadValues, '[Target].[', '[')
SET @PayloadValues = REPLACE(@PayloadValues, '[Source].[', '[')  
SET @PayloadValues = REPLACE(@PayloadValues, '[', '[Source].[')

PRINT 'Original: ' + @Column_List_Insert_Values
PRINT 'After sanitize-then-qualify: ' + @PayloadValues
PRINT ''

-- Test 2: Test the SCD Type 2 pattern
DECLARE @Business_Column_List_Insert_Values NVARCHAR(MAX) = '[S].[Col1],[Source].[Col2],[Target].[Col3],[Col4]'
DECLARE @SelectCols NVARCHAR(MAX) = @Business_Column_List_Insert_Values

SET @SelectCols = REPLACE(@SelectCols, '[S].[', '[')
SET @SelectCols = REPLACE(@SelectCols, '[Source].[', '[')
SET @SelectCols = REPLACE(@SelectCols, '[Target].[', '[')
SET @SelectCols = REPLACE(@SelectCols, '[', '[S].[')

PRINT 'Original: ' + @Business_Column_List_Insert_Values
PRINT 'After sanitize-then-qualify (S): ' + @SelectCols
PRINT ''

-- Test 3: Test META column presence check
DECLARE @Column_List NVARCHAR(MAX) = '[Col1],[META_SOURCE],[Col2]'
DECLARE @meta_current SYSNAME = 'META_CURRENT_RECORD_INDICATOR'
DECLARE @meta_source SYSNAME = 'META_SOURCE'

IF CHARINDEX(QUOTENAME(@meta_current), @Column_List) = 0
    PRINT 'META_CURRENT_RECORD_INDICATOR not found - will add'
ELSE
    PRINT 'META_CURRENT_RECORD_INDICATOR already present - skip'

IF CHARINDEX(QUOTENAME(@meta_source), @Column_List) = 0  
    PRINT 'META_SOURCE not found - will add'
ELSE
    PRINT 'META_SOURCE already present - skip'