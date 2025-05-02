CREATE OR ALTER PROC [sp].[SearchDatabaseForValue] @DatabaseName sysname, --Name of database to be searched
                                      @SearchValue sql_variant, --Value to search for. Ensure that the value passed is of the correct data type
                                      @LeadingWildCard bit = 0, --Will concatenate a leading wildcard is a string based data type
                                      @TrailingWildCard bit = 0, --Will concatenate a trailing wildcard is a string based data type
                                      @DeprecatedTypes bit = 0, --Will include deprecated data types, (n)text and image, if enabled. Could have performance impacts
                                      @OuterSQL nvarchar(MAX) = NULL OUTPUT, --The "outer" dynamic statementm the one that builds the searching SQL
                                      @InnerSQL nvarchar(MAX) = NULL OUTPUT, --The actual SQL that runs against the other database
                                      @WhatIf bit = 0 AS --provide 1 to not actually search the database
BEGIN
/*
Written by Thom A 2024-02-15
Licenced under CC BY-ND 4.0
Targets SQL Server 2017+
*/
    SET NOCOUNT ON;

    /*
    DECLARE @DatabaseName sysname,
            @SearchValue sql_variant,
            @LeadingWildCard bit = 1,
            @TrailingWildCard bit = 1,
            @DeprecatedTypes bit = 0;
    --*/

    DECLARE @CRLF nchar(2) = NCHAR(13) + NCHAR(10),
            @ErrorMessage nvarchar(2047);
    IF NOT EXISTS (SELECT 1 FROM sys.databases WHERE name = @DatabaseName) BEGIN
        SET @ErrorMessage = FORMATMESSAGE(N'Database ''%s'' does not exist.', @DatabaseName);
        THROW 78001, @ErrorMessage, 16;
    END;
    
    IF @WhatIf IS NULL BEGIN
        SET @ErrorMessage = FORMATMESSAGE(N'Msg 62404, Level 1, State 1' + NCHAR(10) +N'%s has a value of NULL. Behaviour will be as if the value is 0.',N'@WhatIf')
        PRINT @ErrorMessage;
        SET @WhatIf = 0;
    END;

    DECLARE @VariantDataType sysname = fn.QuoteSqlvariant(@SearchValue);

    SET @OuterSQL = N'USE ' + QUOTENAME(@DatabaseName) + N';' + @CRLF +
                    N'DECLARE @WhereDelimiter nvarchar(30) = @CRLF + N''   OR '';' + @CRLF +
                    N'WITH Statements AS(' + @CRLF +
                    N'    SELECT N''SELECT N'' + QUOTENAME(s.name,'''''''') + N'' AS [[SchemaName]]],'' + @CRLF +' + @CRLF +
                    N'           N''       N'' + QUOTENAME(t.name,'''''''') + N'' AS [[TableName]]],'' + @CRLF +' + @CRLF +
                    N'           N''       *'' + @CRLF +' + @CRLF +
                    N'           N''INTO '' + QUOTENAME(CONCAT(N''#'',s.name,t.name)) + @CRLF +' + @CRLF +
                    N'           N''FROM '' + QUOTENAME(s.name) + N''.'' + QUOTENAME(t.name) + @CRLF +' + @CRLF +
                    N'           N''WHERE '' + STRING_AGG(CONVERT(nvarchar(MAX),N'''') + ' + @CRLF +
                    N'                                    QUOTENAME(c.name) + CASE WHEN 1 IN (@LeadingWildCard,@TrailingWildCard) THEN N'' LIKE '' ELSE '' = '' END +' + @CRLF +
                    N'                                    CASE WHEN @LeadingWildCard = 1 AND CONVERT(sysname,SQL_VARIANT_PROPERTY(@SearchValue,''BaseType'')) LIKE ''%char'' THEN N''''''%''''+'' ELSE N'''' END + ' + @CRLF +
                    N'                                    N''CONVERT('' + @VariantDataType + N'',@SearchValue)'' + ' + @CRLF +
                    N'                                    CASE WHEN @TrailingWildCard = 1 AND CONVERT(sysname,SQL_VARIANT_PROPERTY(@SearchValue,''BaseType'')) LIKE ''%char''  THEN N''+''''%'''''' ELSE N'''' END, @WhereDelimiter) + N'';'' + @CRLF +' + @CRLF +
                    N'           N''IF EXISTS (SELECT 1 FROM '' + QUOTENAME(CONCAT(N''#'',s.name,t.name)) + N'') SELECT * FROM '' + QUOTENAME(CONCAT(N''#'',s.name,t.name)) + N'';'' + @CRLF +' + @CRLF +
                    N'           N''DROP TABLE '' + QUOTENAME(CONCAT(N''#'',s.name,t.name)) + N'';'' AS Statement' + @CRLF +
                    N'    FROM sys.schemas s' + @CRLF +
                    N'         JOIN sys.tables t ON s.schema_id = t.schema_id' + @CRLF +
                    N'         JOIN sys.columns c ON t.object_id = c.object_id' + @CRLF +
                    N'         JOIN sys.types ct ON c.user_type_id = ct.user_type_id' + @CRLF +
                    N'    WHERE ct.name IN (CONVERT(sysname,SQL_VARIANT_PROPERTY(@SearchValue,''BaseType'')),REPLACE(CONVERT(sysname,SQL_VARIANT_PROPERTY(@SearchValue,''BaseType'')),''var'',''''))' + @CRLF +
                    N'       OR (ct.name LIKE ''%int'' AND CONVERT(sysname,SQL_VARIANT_PROPERTY(@SearchValue,''BaseType'')) LIKE ''%int'')' + @CRLF +
                    N'       OR (@DeprecatedTypes = 1 AND REPLACE(REPLACE(ct.name,''text'',''varchar''),''image'',''binary'') IN (CONVERT(sysname,SQL_VARIANT_PROPERTY(@SearchValue,''BaseType'')),REPLACE(CONVERT(sysname,SQL_VARIANT_PROPERTY(@SearchValue,''BaseType'')),''var'','''')))' + @CRLF +
                    N'    GROUP BY s.name,' + @CRLF +
                    N'             t.name)' + @CRLF +
                    N'SELECT @InnerSQL = STRING_AGG(S.Statement,@CRLF)' + @CRLF +
                    N'FROM Statements S;' + @CRLF + 
                    N'IF @WhatIf = 0' + @CRLF + 
                    N'    EXEC sys.sp_executesql @InnerSQL, N''@SearchValue sql_variant'', @SearchValue;';

    --PRINT @OuterSQL;

    EXEC sys.sp_executesql @OuterSQL, N'@SearchValue sql_variant, @VariantDataType sysname, @LeadingWildCard bit, @TrailingWildCard bit, @DeprecatedTypes bit, @CRLF nchar(2), @InnerSQL nvarchar(MAX) OUTPUT, @WhatIf bit', @SearchValue, @VariantDataType, @LeadingWildCard, @TrailingWildCard, @DeprecatedTypes, @CRLF, @InnerSQL OUTPUT, @WhatIf;
END;
GO