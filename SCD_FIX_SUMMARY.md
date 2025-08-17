# SCD Qualifier Bug Fix Summary

## Problem Description
The SCD (Slowly Changing Dimension) implementation in `sp_generate_merge` had a bug where generated SQL contained repeated qualifiers like `[Source].[Source].META_SOURCE` in:
1. NOT MATCHED BY TARGET VALUES list  
2. SCD Type 2 post-MERGE INSERT SELECT list

## Root Cause
The issue was caused by naive global string replacement:
```sql
-- OLD (problematic) code:
REPLACE(@Column_List_Insert_Values, '[', '[Source].[')
```

When `@Column_List_Insert_Values` already contained qualified names like `[Source].[META_SOURCE]`, this would result in `[Source].[Source].[META_SOURCE]`.

## Solution Implemented
Implemented a **sanitize-then-qualify** pattern that:
1. Strips existing qualifiers first
2. Then applies the desired qualifier once

### For NOT MATCHED BY TARGET VALUES (line ~1097):
```sql
-- Sanitize-then-qualify approach: Strip existing qualifiers before applying [Source]. prefix
-- This prevents repeated qualifiers like [Source].[Source] when columns are already qualified
SET @PayloadValues = @Column_List_Insert_Values COLLATE DATABASE_DEFAULT
SET @PayloadValues = REPLACE(@PayloadValues, '[Target].[', '[')
SET @PayloadValues = REPLACE(@PayloadValues, '[Source].[', '[')
SET @PayloadValues = REPLACE(@PayloadValues, '[', '[Source].[')

SET @outputMergeBatch += @b COLLATE DATABASE_DEFAULT + ' VALUES(' + @PayloadValues + ')'
```

### For SCD Type 2 INSERT SELECT (line ~1150):
```sql
-- Sanitize-then-qualify approach: Strip existing qualifiers before applying [S]. prefix for alias S
-- This prevents repeated qualifiers in the SELECT list
SET @SelectCols = @Business_Column_List_Insert_Values
SET @SelectCols = REPLACE(@SelectCols, '[S].[', '[')
SET @SelectCols = REPLACE(@SelectCols, '[Source].[', '[')
SET @SelectCols = REPLACE(@SelectCols, '[Target].[', '[')
SET @SelectCols = REPLACE(@SelectCols, '[', '[S].[')

SET @outputMergeBatch += @b COLLATE DATABASE_DEFAULT + 'SELECT ' + @SelectCols + ','
```

### Robust META Column Addition (line ~730):
```sql
-- Add META* columns to column lists (only if not already present)
IF CHARINDEX(QUOTENAME(@meta_current), @Column_List) = 0
    SET @Column_List += ',' + QUOTENAME(@meta_current)
-- ... (repeated for each META column)
```

## Files Modified
- `sp_generate_merge.sql`: Main stored procedure with the fixes

## Variables Added
- `@PayloadValues`: Holds sanitized values for NOT MATCHED BY TARGET
- `@SelectCols`: Holds sanitized columns for SCD Type 2 INSERT SELECT

## Backward Compatibility
- ✅ No changes when `@scd_type = 0` (normal operation)
- ✅ All existing functionality preserved
- ✅ Azure SQL compatibility maintained
- ✅ NOT MATCHED BY SOURCE DELETE suppression maintained for SCD

## Testing
Created comprehensive test cases in `/tmp/` that validate:
1. Repeated qualifier elimination
2. Backward compatibility  
3. End-to-end SCD scenarios
4. Edge cases and special column types

## Acceptance Criteria Met
- ✅ NOT MATCHED BY TARGET INSERT VALUES contains exactly one `[Source].` qualification per identifier
- ✅ SCD Type 2 INSERT SELECT contains exactly one `[S].` qualification per identifier  
- ✅ No behavior changes when `@scd_type = 0`
- ✅ Robust META column duplicate prevention
- ✅ Clear comments explaining sanitize-then-qualify pattern

## Examples of Fixed Output

### Before Fix (❌):
```sql
VALUES([Source].[CustomerID], [Source].[CustomerName], [Source].[Source].[META_SOURCE])
```

### After Fix (✅):
```sql  
VALUES([Source].[CustomerID], [Source].[CustomerName], [Source].[META_SOURCE])
```

The fix eliminates all instances of repeated qualifiers while maintaining proper SQL syntax and functionality.