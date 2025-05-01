# SearchDatabaseForValue
A procedure to search an entire database for a specific value.

# Requirements
SQL Server 2017+

Azure SQL Database is not supported, as these are contained databases, and do not allow for use of USE statements or 3+ part naming on objects.

# Usage

## Syntax

```sql
[DECLARE @<SearchValue> sql_variant = CONVERT(<data type>,<search value>) [;]]

EXECUTE dbo.SearchDatabaseForValue [@DatabaseName =] <nvarchar>
                                   , [ @SearchValue = ] <sql_variant>
                                   [, @LeadingWildCard = <bit>]
                                   [, @TrailingWildCard = <bit>]
                                   [, @DeprecatedTypes = <bit>]
                                   [, @OuterSQL = <nvarchar> OUTPUT]
                                   [, @InnerSQL = <nvarchar> OUTPUT]
                                   [, @WhatIf = <bit>][;]
```