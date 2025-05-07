CREATE OR ALTER FUNCTION [dbo].[QuoteSqlvariant] (@SQLVariant sql_variant) 
RETURNS nvarchar(258) 
WITH SCHEMABINDING
AS 
/*
Written by Thom A 2021-03-21
Original Source: https://wp.larnu.uk/sql_variant-and-dynamic-sql/
Licenced under CC BY-ND 4.0
*/
BEGIN
    RETURN QUOTENAME(CONVERT(sysname,SQL_VARIANT_PROPERTY(@SQLVariant,'BaseType'))) +
           CASE WHEN CONVERT(sysname,SQL_VARIANT_PROPERTY(@SQLVariant,'BaseType')) IN (N'char',N'varchar') THEN CONCAT(N'(',CONVERT(int,SQL_VARIANT_PROPERTY(@SQLVariant,'MaxLength')),N')')
                WHEN CONVERT(sysname,SQL_VARIANT_PROPERTY(@SQLVariant,'BaseType')) IN (N'nchar',N'nvarchar') THEN CONCAT(N'(',CONVERT(int,SQL_VARIANT_PROPERTY(@SQLVariant,'MaxLength'))/2,N')')
                WHEN CONVERT(sysname,SQL_VARIANT_PROPERTY(@SQLVariant,'BaseType')) IN (N'datetime2',N'datetimeoffset',N'time') THEN CONCAT(N'(',CONVERT(int,SQL_VARIANT_PROPERTY(@SQLVariant,'Scale')),N')')
                WHEN CONVERT(sysname,SQL_VARIANT_PROPERTY(@SQLVariant,'BaseType')) IN (N'decimal',N'numeric',N'time') THEN CONCAT(N'(',CONVERT(int,SQL_VARIANT_PROPERTY(@SQLVariant,'Precision')),N',',CONVERT(int,SQL_VARIANT_PROPERTY(@SQLVariant,'Scale')),N')')
                WHEN CONVERT(sysname,SQL_VARIANT_PROPERTY(@SQLVariant,'BaseType')) IN (N'varbinary') THEN CONCAT(N'(',CONVERT(int,SQL_VARIANT_PROPERTY(@SQLVariant,'TotalBytes'))-4,N')')
                ELSE N''
           END;
END
GO


