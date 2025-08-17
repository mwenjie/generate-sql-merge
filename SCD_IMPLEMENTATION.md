# SCD (Slowly Changing Dimension) Enhancement

This implementation extends sp_generate_merge.sql to support SCD Type 1 and Type 2 logic using standardized META* columns.

## New Parameters

- `@scd_type tinyint = 0`: 0 (disabled), 1 (SCD Type 1), 2 (SCD Type 2)
- `@asof_expression nvarchar(128) = N'SYSUTCDATETIME()'`: Expression for effective/expiry timestamps
- `@meta_current sysname = N'META_CURRENT_RECORD_INDICATOR'`: Current record indicator column name
- `@meta_effective sysname = N'META_EFFECTIVE_DATETIME'`: Effective datetime column name
- `@meta_expiry sysname = N'META_EXPIRY_DATETIME'`: Expiry datetime column name
- `@meta_key_checksum sysname = N'META_KEY_CHECKSUM'`: Key checksum column name
- `@meta_record_checksum sysname = N'META_RECORD_CHECKSUM'`: Record checksum column name
- `@meta_source sysname = N'META_SOURCE'`: Source system column name

## Target Table Schema Requirements

When SCD is enabled, the target table must contain these columns:
1. `META_CURRENT_RECORD_INDICATOR` (bit)
2. `META_EFFECTIVE_DATETIME` (datetime2)
3. `META_EXPIRY_DATETIME` (datetime2)
4. `META_KEY_CHECKSUM` (varchar(64))
5. `META_RECORD_CHECKSUM` (varchar(64))
6. `META_SOURCE` (varchar/nvarchar)

## Source Table Schema Requirements

When SCD is enabled, the source/staging table must contain:
- `META_SOURCE` column
- All business key and data columns

## SCD Type 1 Behavior

- Overwrites existing records in place
- Updates both business data and META columns
- Uses `META_RECORD_CHECKSUM` for change detection
- Maintains single version per business key
- Updates `META_EFFECTIVE_DATETIME`, `META_KEY_CHECKSUM`, `META_RECORD_CHECKSUM`, and `META_SOURCE`

## SCD Type 2 Behavior

- Expires existing records (sets `META_CURRENT_RECORD_INDICATOR = 0`)
- Sets `META_EXPIRY_DATETIME` to current timestamp
- Uses composite-key OUTPUT + follow-up INSERT pattern
- Inserts new records for changed data with current indicators
- Maintains historical versions

## Checksum Computation

- `META_KEY_CHECKSUM`: SHA2_256 hash of business key columns
- `META_RECORD_CHECKSUM`: SHA2_256 hash of non-key business data columns
- Both are rendered as hex strings using `CONVERT(varchar(64), HASHBYTES('SHA2_256', ...), 2)`

## Change Detection

- SCD mode uses `META_RECORD_CHECKSUM` for change detection
- Conflicts with `@hash_compare_column` (validation error if both used)
- Only processes records where checksums differ

## Validation Rules

- `@scd_type` must be 0, 1, or 2
- Cannot combine SCD with `@hash_compare_column`
- Cannot use `@delete_if_not_matched=1` with SCD Type 2
- Source table must contain `META_SOURCE` when SCD enabled
- Target table must contain all META* columns when SCD enabled

## Backward Compatibility

- When `@scd_type = 0` (default), procedure works exactly as before
- All new parameters have sensible defaults
- No impact on existing usage patterns

## Usage Examples

### SCD Type 1
```sql
EXEC sp_generate_merge 
    @table_name = 'SourceTable',
    @target_table = '[warehouse].[TargetTable]',
    @scd_type = 1,
    @include_values = 0;
```

### SCD Type 2
```sql
EXEC sp_generate_merge 
    @table_name = 'SourceTable', 
    @target_table = '[warehouse].[TargetTable]',
    @scd_type = 2,
    @include_values = 0;
```

## Generated SQL Structure

The implementation generates:
1. `DECLARE @asof datetime2(7) = {asof_expression};`
2. MERGE statement with computed META* columns in USING clause
3. WHEN MATCHED with checksum-based change detection
4. WHEN NOT MATCHED BY TARGET for inserts
5. For SCD Type 2: Follow-up INSERT for new record versions

This provides a standardized, efficient approach to SCD processing while maintaining the existing flexibility and power of sp_generate_merge.