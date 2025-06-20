# SearchDatabaseForValue
A procedure to search an entire database for a specific value.

# Requirements
SQL Server 2017+ - SearchDatabaseForValue
SQL Server 2008+ - SearchDatabaseForValue_XML

Azure SQL Database is supported, provided that the database name parameter is the same as the database that the procedure is created is.

# Deployment 
Execute the `QuoteSqlvariant.sql` (within `fn/Functions`) and then `SearchDatabaseForValue.sql` and/or `SearchDatabaseForValue_XML.sql` scripts (within `sp/StoredProcedures`) in your desired database. The schemas can be changed without issue (ensure that if you deploy `QuoteSqlvariant` to a different schema that you update the schema in `SearchDatabaseForValue`'s definition).

# Usage

It is highly recommend to use a variable of the desired data type to pass to the `@SearchValue` parameter; this ensure that the expected data type(s) are searched for. This also makes it possible to search date and time values, as literals for these data types don't exist.

## Syntax

```sql
[DECLARE @<SearchValue> <data type> = <search value> [;]]

[ EXECUTE | EXEC ] dbo.SearchDatabaseForValue[_XML] [@DatabaseName =] <sysname>
                                                    , [ @SearchValue = ] <sql_variant>
                                                    [, @SearchIsPattern = <bit>]
                                                    [, @DeprecatedTypes = <bit>]
                                                    [, @OuterSQL = <nvarchar> OUTPUT]
                                                    [, @InnerSQL = <nvarchar> OUTPUT]
                                                    [, @WhatIf = <bit>][;]
```

## Arguments

### @DatabaseName

The database name you wish to search within. 

`@DatabaseName` is required.

### @SearchValue

It is recommended to define a variable to pass to the `@SearchValue` parameter with the explicit data type of the value you are searching, as the parameter is defined as a `sql_variant`. This ensures that the data type(s) being searched are the expected data type. `(n)char`/`(n)varchar` and `binary/varbinary` (not `(var)char` and `n(var)char`) are treated as the same data type for searching; `(n)text`/`image` will be seen as equal respectively if `@DeprecatedTypes` is enabled. As an example the passing the `nvarchar` value `N'SearchValue'` to `@SearchValue` will search both `nchar` and `nvarchar` columns, and `ntext` columns if `@DeprecatedTypes` is set to `1`.

> #### Note
> `sql_variant` itself does not support `MAX` length values, or `image`/`text`. Use a length non-`MAX` length and/or `(n)varchar`.

Only a single value can be searched at a time; if multiple different values need to be searched for, then multiple executions will need to be done.

`@SearchValue` is required.

### @SearchIsPattern

Cause a a `LIKE` expression instead of an `=` to be used for the filter predicate, therefore enabling use of wildcard usage in `@SearchValue`. Has no affect if `@SearchValue` is not a `(n)(var)char`.

`@SearchIsPattern` is not required and defaults to `0`; a value of `NULL` will be treated as `0` and informational warning 62404 will be raised.

### @DeprecatedTypes

Will also search `(n)text` and `image` data types if an appropriate data type is passed to `@SearchValue`. Enabling `@DeprecatedTypes` may result is (significantly) slower performance on environments where the data type(s) have been used extensively, as they are unable to be indexed.

`@DeprecatedTypes` is not required and defaults to `0`; a value of `NULL` will be treated as `0` and informational warning 62404 will be raised.

### @OuterSQL

This returns the outer dynamic SQL query, which builds the dynamic statement to be run against every table in the parametrised database. 

`@OuterSQL` is not required. Any value passed to the parameter will be overwritten.

### @InnerSQL

This returns the inner dynamic SQL query, which contains the statements run against every table in the parametrised database. 

`@InnerSQL` is not required. Any value passed to the parameter will be overwritten.

### @WhatIf

A bit to denote that no statements should be run against the data. If set to `1` the statements are only prepared and not executed. Should be used alongside `@InnerSQL` and `@OuterSQL` to obtain what statement(s) will have been executed.

`@WhatIf` is not required. The default value is `0`; a value of `NULL` will be treated as `0` and informational warning 62404 will be raised.

# Result Sets

The procedure will return all rows, containing all columns, from the tables where it finds the value being searched for. Each dataset will also have 2 additional columns prefixed as their first 2 columns, to denote the schema and table names of the object the data was located in. These columns are named `[SchemaName]` and `[TableName]` respectively (note the braces are part of their name to help avoid collision).

> #### Warning
>  *If* your database does contain a column which shares a name with these two columns, `SearchDatabaseForValue` will fail.

# Examples:

## Search a database for a specific word

Search a database for a specific `nvarchar` value `N'Chloe'`; this will only search `nvarchar` and `nchar` columns in the database `MyDatabase`:
```sql
EXEC dbo.SearchDatabaseForValue N'MyDatabase', N'Chloe';
```

## Search for values starting with a value, including deprecate types

Search `varchar` and `char` columns in the database `YourDatabase` for values that start with `'Hotel'`. This will include `text` columns, due to the enabled of `@DeprecatedTypes`:
```sql

EXEC dbo.SearchDatabaseForValue @DatabaseName = N'YourDatabase',
                                @SearchValue = 'Hotel%'
                                @SearchIsPattern = 1,
                                @DeprecatedTypes = 1;
```

## Search for values containing a string with a wildcard

Search `varchar` and `char` columns in the database `YourDatabase` that contain a value where `12` followed by any character and then `45`. 
```sql
EXEC dbo.SearchDatabaseForValue @DatabaseName = N'YourDatabase',
                                @SearchValue = '%12_45%'
                                @SearchIsPattern = 1;
```

## Search for a specific date and time value

Use variable of the type `datetime2` to locate any rows in the database that contain the same exact date and time in a `datetime2` column:
```sql
DECLARE @SearchDateTime datetime2(3) = '2025-03-04T17:19:23.524';

EXEC dbo.SearchDatabaseForValue @DatabaseName = N'MyDatabase',
                                @SearchValue = @SearchDateTime;
```

## Use WhatIf to not run the query, and obtain the dynamic statement that would be run against a database

```sql
DECLARE @SearchTime time(1) = '12:37:19:54',
        @SearchSQL nvarchar(MAX);

EXEC dbo.SearchDatabaseForValue @DatabaseName = N'MyDatabase',
                                @SearchValue = @SearchTime,
                                @InnerSQL = @SearchSQL OUTPUT,
                                @WhatIf = 1;

SELECT @SearchSQL;
```