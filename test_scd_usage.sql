-- Comprehensive test for SCD Type 1 and Type 2 functionality
-- This demonstrates how to use the enhanced sp_generate_merge with SCD support

-- Example usage for SCD Type 1:
/*
DECLARE @output NVARCHAR(MAX);
EXEC sp_generate_merge 
    @table_name = 'SourceTable',
    @target_table = '[warehouse].[TargetTable]',
    @scd_type = 1,
    @include_values = 0,
    @asof_expression = N'SYSUTCDATETIME()',
    @meta_current = N'META_CURRENT_RECORD_INDICATOR',
    @meta_effective = N'META_EFFECTIVE_DATETIME', 
    @meta_expiry = N'META_EXPIRY_DATETIME',
    @meta_key_checksum = N'META_KEY_CHECKSUM',
    @meta_record_checksum = N'META_RECORD_CHECKSUM',
    @meta_source = N'META_SOURCE',
    @output = @output OUTPUT,
    @results_to_text = NULL;

PRINT @output;
*/

-- Example usage for SCD Type 2:
/*
DECLARE @output NVARCHAR(MAX);
EXEC sp_generate_merge 
    @table_name = 'SourceTable',
    @target_table = '[warehouse].[TargetTable]',
    @scd_type = 2,
    @include_values = 0,
    @asof_expression = N'GETUTCDATE()',
    @output = @output OUTPUT,
    @results_to_text = NULL;

PRINT @output;
*/

-- Key features of the SCD implementation:

PRINT '=== SCD Type 1 and Type 2 Features ===';
PRINT '';
PRINT '1. SCD Type 1 (Overwrite):';
PRINT '   - Updates existing records in place';
PRINT '   - Preserves business data and updates META columns';
PRINT '   - Uses META_RECORD_CHECKSUM for change detection';
PRINT '   - Maintains single version per business key';
PRINT '';
PRINT '2. SCD Type 2 (Versioning):';
PRINT '   - Expires existing records (sets META_CURRENT_RECORD_INDICATOR = 0)';
PRINT '   - Creates new records for changed data';
PRINT '   - Maintains historical versions';
PRINT '   - Uses composite-key OUTPUT + follow-up INSERT pattern';
PRINT '';
PRINT '3. Meta Column Handling:';
PRINT '   - META_CURRENT_RECORD_INDICATOR: 1 for current, 0 for historical';
PRINT '   - META_EFFECTIVE_DATETIME: When record became effective';
PRINT '   - META_EXPIRY_DATETIME: When record expired (9999-12-31 for current)';
PRINT '   - META_KEY_CHECKSUM: SHA2_256 hash of business key columns';
PRINT '   - META_RECORD_CHECKSUM: SHA2_256 hash of business data columns';
PRINT '   - META_SOURCE: Source system identifier';
PRINT '';
PRINT '4. New Parameters:';
PRINT '   - @scd_type: 0 (disabled), 1 (Type 1), 2 (Type 2)';
PRINT '   - @asof_expression: Expression for effective/expiry timestamps';
PRINT '   - @meta_*: Column name overrides for META columns';
PRINT '';
PRINT '5. Validation Rules:';
PRINT '   - Cannot use @hash_compare_column with SCD (uses META_RECORD_CHECKSUM)';
PRINT '   - Cannot use @delete_if_not_matched=1 with SCD Type 2';
PRINT '   - SCD assumes target table has all META* columns';
PRINT '   - SCD assumes source table has META_SOURCE column';
PRINT '';

-- Example table schema for testing:
PRINT '=== Example Table Schemas ===';
PRINT '';
PRINT 'Source Table:';
PRINT 'CREATE TABLE SourceTable (';
PRINT '    CustomerID INT,';
PRINT '    CustomerName VARCHAR(100),';
PRINT '    Email VARCHAR(100),';
PRINT '    Phone VARCHAR(20),';
PRINT '    META_SOURCE VARCHAR(50)';
PRINT ');';
PRINT '';
PRINT 'Target Table (SCD-enabled):';
PRINT 'CREATE TABLE TargetTable (';
PRINT '    CustomerID INT,';
PRINT '    CustomerName VARCHAR(100),';
PRINT '    Email VARCHAR(100),';
PRINT '    Phone VARCHAR(20),';
PRINT '    META_CURRENT_RECORD_INDICATOR BIT,';
PRINT '    META_EFFECTIVE_DATETIME DATETIME2(7),';
PRINT '    META_EXPIRY_DATETIME DATETIME2(7),';
PRINT '    META_KEY_CHECKSUM VARCHAR(64),';
PRINT '    META_RECORD_CHECKSUM VARCHAR(64),';
PRINT '    META_SOURCE VARCHAR(50)';
PRINT ');';
PRINT '';

-- Backward compatibility note:
PRINT '=== Backward Compatibility ===';
PRINT 'When @scd_type = 0 (default), the procedure works exactly';
PRINT 'as before with no changes to existing functionality.';
PRINT 'All new parameters have sensible defaults.';
PRINT '';

PRINT 'SCD test documentation complete.';