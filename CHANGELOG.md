# 2025-06-17
Move to DB project style and put (back) into respective schemas.

# 2025-05-13
Add version that uses the old `FOR XML PATH` (and `STUFF`) method, for SQL Server 2016, and prior, environments; `dbo.SearchDatababaseForValue_XML`.
> #### Note
> This version is likely to also be deprecated almost immediately.

# 2025-05-12 
Switch to parameterised procedure name, rather than a `USE` statement.

## Breaking Change
Remove the Leading and Trailing Parameters, and switch to a Search is Pattern parameter. This will break existing workflows, if they use the old parameters.

# 2025-05-07
Add support for columns using an alias type. The system type needs to be passed to `@SearchValue`, but the procedure now searches the system type instead.