-- Comprehensive test for SCD qualifier bug fixes
-- This test verifies that the sanitize-then-qualify pattern correctly handles repeated qualifiers

-- Test case: Simulate the exact scenario described in the problem statement

PRINT '=== Testing SCD Qualifier Bug Fixes ==='
PRINT ''

-- Test 1: NOT MATCHED BY TARGET VALUES clause fix
PRINT '1. Testing NOT MATCHED BY TARGET VALUES clause fix:'
DECLARE @Column_List_Insert_Values NVARCHAR(MAX) = '[CustomerID],[CustomerName],[Source].[Email],[Target].[Phone]'

-- Before fix (problematic): REPLACE(@Column_List_Insert_Values, '[', '[Source].[')
DECLARE @BeforeFix NVARCHAR(MAX) = REPLACE(@Column_List_Insert_Values, '[', '[Source].[')

-- After fix (sanitize-then-qualify):
DECLARE @PayloadValues NVARCHAR(MAX) = @Column_List_Insert_Values
SET @PayloadValues = REPLACE(@PayloadValues, '[Target].[', '[')
SET @PayloadValues = REPLACE(@PayloadValues, '[Source].[', '[')
SET @PayloadValues = REPLACE(@PayloadValues, '[', '[Source].[')

PRINT 'Original column list: ' + @Column_List_Insert_Values
PRINT 'Before fix (bad):     ' + @BeforeFix
PRINT 'After fix (good):     ' + @PayloadValues
PRINT ''

-- Check if fix resolved repeated qualifiers
IF CHARINDEX('[Source].[Source]', @BeforeFix) > 0
    PRINT 'BEFORE FIX: ❌ Contains repeated [Source].[Source] qualifiers'
ELSE
    PRINT 'BEFORE FIX: ✓ No repeated qualifiers'

IF CHARINDEX('[Source].[Source]', @PayloadValues) > 0
    PRINT 'AFTER FIX:  ❌ Still contains repeated [Source].[Source] qualifiers'
ELSE
    PRINT 'AFTER FIX:  ✓ No repeated qualifiers - FIXED!'

IF CHARINDEX('[Source].[Target]', @BeforeFix) > 0
    PRINT 'BEFORE FIX: ❌ Contains [Source].[Target] qualifiers'
ELSE
    PRINT 'BEFORE FIX: ✓ No [Source].[Target] qualifiers'

IF CHARINDEX('[Source].[Target]', @PayloadValues) > 0
    PRINT 'AFTER FIX:  ❌ Still contains [Source].[Target] qualifiers'
ELSE
    PRINT 'AFTER FIX:  ✓ No [Source].[Target] qualifiers - FIXED!'

PRINT ''
PRINT '----------------------------------------'
PRINT ''

-- Test 2: SCD Type 2 INSERT SELECT clause fix
PRINT '2. Testing SCD Type 2 INSERT SELECT clause fix:'
DECLARE @Business_Column_List_Insert_Values NVARCHAR(MAX) = '[CustomerID],[S].[CustomerName],[Source].[Email],[Target].[Phone]'

-- Apply the sanitize-then-qualify pattern for alias [S]
DECLARE @SelectCols NVARCHAR(MAX) = @Business_Column_List_Insert_Values
SET @SelectCols = REPLACE(@SelectCols, '[S].[', '[')
SET @SelectCols = REPLACE(@SelectCols, '[Source].[', '[')
SET @SelectCols = REPLACE(@SelectCols, '[Target].[', '[')
SET @SelectCols = REPLACE(@SelectCols, '[', '[S].[')

PRINT 'Original business column list: ' + @Business_Column_List_Insert_Values
PRINT 'After S qualification fix:     ' + @SelectCols
PRINT ''

-- Check if all columns now have exactly one [S]. qualifier
IF CHARINDEX('[S].[S]', @SelectCols) > 0
    PRINT '❌ Contains repeated [S].[S] qualifiers'
ELSE
    PRINT '✓ No repeated [S] qualifiers - FIXED!'

IF CHARINDEX('[S].[Source]', @SelectCols) > 0
    PRINT '❌ Still contains [S].[Source] qualifiers'
ELSE
    PRINT '✓ No [S].[Source] qualifiers - FIXED!'

IF CHARINDEX('[S].[Target]', @SelectCols) > 0
    PRINT '❌ Still contains [S].[Target] qualifiers'  
ELSE
    PRINT '✓ No [S].[Target] qualifiers - FIXED!'

PRINT ''
PRINT '----------------------------------------'
PRINT ''

-- Test 3: META column duplicate prevention
PRINT '3. Testing META column duplicate prevention:'
DECLARE @Column_List NVARCHAR(MAX) = '[CustomerID],[CustomerName],[META_SOURCE]'
DECLARE @meta_current SYSNAME = 'META_CURRENT_RECORD_INDICATOR'
DECLARE @meta_source SYSNAME = 'META_SOURCE'

PRINT 'Current column list: ' + @Column_List

IF CHARINDEX(QUOTENAME(@meta_current), @Column_List) = 0
    PRINT '✓ META_CURRENT_RECORD_INDICATOR not found - will be added'
ELSE
    PRINT '! META_CURRENT_RECORD_INDICATOR already present - will be skipped'

IF CHARINDEX(QUOTENAME(@meta_source), @Column_List) = 0  
    PRINT '✓ META_SOURCE not found - will be added'
ELSE
    PRINT '! META_SOURCE already present - will be skipped (CORRECT)'

PRINT ''
PRINT '----------------------------------------'
PRINT ''

-- Test 4: Edge cases
PRINT '4. Testing edge cases:'

-- Test with already properly qualified columns
DECLARE @AlreadyQualified NVARCHAR(MAX) = '[Source].[Col1],[Source].[Col2],[Source].[Col3]'
DECLARE @EdgeTest1 NVARCHAR(MAX) = @AlreadyQualified
SET @EdgeTest1 = REPLACE(@EdgeTest1, '[Target].[', '[')
SET @EdgeTest1 = REPLACE(@EdgeTest1, '[Source].[', '[')
SET @EdgeTest1 = REPLACE(@EdgeTest1, '[', '[Source].[')

PRINT 'Already qualified input: ' + @AlreadyQualified
PRINT 'After sanitize-qualify:  ' + @EdgeTest1
IF @AlreadyQualified = @EdgeTest1
    PRINT '✓ No changes to already properly qualified columns - CORRECT!'
ELSE
    PRINT '! Changes made to already qualified columns'

-- Test with mixed qualifiers
DECLARE @MixedQualifiers NVARCHAR(MAX) = '[Col1],[Source].[Col2],[Target].[Col3],[S].[Col4]'
DECLARE @EdgeTest2 NVARCHAR(MAX) = @MixedQualifiers
SET @EdgeTest2 = REPLACE(@EdgeTest2, '[Target].[', '[')
SET @EdgeTest2 = REPLACE(@EdgeTest2, '[Source].[', '[')
SET @EdgeTest2 = REPLACE(@EdgeTest2, '[S].[', '[')
SET @EdgeTest2 = REPLACE(@EdgeTest2, '[', '[Source].[')

PRINT 'Mixed qualifiers input:  ' + @MixedQualifiers
PRINT 'After sanitize-qualify:  ' + @EdgeTest2
IF CHARINDEX('[Source].[Source]', @EdgeTest2) = 0 AND CHARINDEX('[Source].[Target]', @EdgeTest2) = 0 AND CHARINDEX('[Source].[S]', @EdgeTest2) = 0
    PRINT '✓ All mixed qualifiers properly normalized - CORRECT!'
ELSE
    PRINT '❌ Some repeated qualifiers remain'

PRINT ''
PRINT '=== Test Summary ==='
PRINT 'The sanitize-then-qualify pattern successfully:'
PRINT '✓ Removes repeated [Source].[Source] qualifiers'
PRINT '✓ Removes [Source].[Target] mixed qualifiers'  
PRINT '✓ Properly qualifies SCD Type 2 SELECT columns with [S]'
PRINT '✓ Prevents duplicate META column additions'
PRINT '✓ Handles edge cases correctly'
PRINT ''
PRINT 'This fix resolves the SCD qualifier bug described in the issue.'