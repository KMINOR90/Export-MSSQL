--- Sql code to find Table info.

USE distribution;
GO

SELECT 
    table_name 
FROM 
    information_schema.tables 
WHERE 
    table_type = 'BASE TABLE';

----Sql DB name and Table name--

DECLARE @sql NVARCHAR(MAX);
SET @sql = N'';

-- Generate SQL to query all databases
SELECT @sql = @sql + 'IF EXISTS (SELECT * FROM [' + name + '].information_schema.tables WHERE table_type = ''BASE TABLE'') ' +
    'BEGIN ' +
    'USE [' + name + ']; ' +
    'SELECT ''' + name + ''' AS DatabaseName, table_name ' +
    'FROM information_schema.tables WHERE table_type = ''BASE TABLE''; ' +
    'END; '
FROM sys.databases
WHERE state_desc = 'ONLINE' AND name NOT IN ('master', 'tempdb', 'model', 'msdb');

-- Execute the generated SQL
EXEC sp_executesql @sql;




---information about index usage statistics for all user tables in the current database. 
--It focuses on the timing of the last index operations, such as seek, scan, lookup, and update, and sorts the results by the most recent update time.

SELECT 
    OBJECT_NAME(i.object_id) AS TableName,
    MAX(ius.last_user_seek) AS LastSeekTime,
    MAX(ius.last_user_scan) AS LastScanTime,
    MAX(ius.last_user_lookup) AS LastLookupTime,
    MAX(ius.last_user_update) AS LastUpdateTime
FROM 
    sys.dm_db_index_usage_stats AS ius
JOIN 
    sys.indexes AS i ON i.object_id = ius.object_id AND i.index_id = ius.index_id
WHERE 
    ius.database_id = DB_ID()  -- current database
    AND OBJECTPROPERTY(i.object_id, 'IsUserTable') = 1
GROUP BY 
    i.object_id
ORDER BY 
    MAX(ius.last_user_update) DESC;


----This SQL does the same as above but for Databases
SELECT 
    DB_NAME(database_id) AS DatabaseName,
    MAX(last_user_seek) AS LastSeekTime,
    MAX(last_user_scan) AS LastScanTime,
    MAX(last_user_lookup) AS LastLookupTime,
    MAX(last_user_update) AS LastUpdateTime
FROM 
    sys.dm_db_index_usage_stats
WHERE 
    database_id = DB_ID()  -- current database
GROUP BY 
    database_id;
 
 -------- Database not being used
 SELECT 
    d.name AS DatabaseName
FROM 
    sys.databases d
LEFT JOIN 
    sys.dm_db_index_usage_stats ius
    ON d.database_id = ius.database_id
GROUP BY 
    d.name, d.database_id
HAVING 
    MAX(ius.last_user_seek) IS NULL AND
    MAX(ius.last_user_scan) IS NULL AND
    MAX(ius.last_user_lookup) IS NULL AND
    MAX(ius.last_user_update) IS NULL
ORDER BY 
    d.name;
----------Tables not being used
SELECT 
    t.name AS TableName
FROM 
    sys.tables t
LEFT JOIN 
    sys.indexes i ON t.object_id = i.object_id
LEFT JOIN 
    sys.dm_db_index_usage_stats ius 
    ON ius.object_id = i.object_id 
    AND ius.index_id = i.index_id 
    AND ius.database_id = DB_ID()
GROUP BY 
    t.name
HAVING 
    MAX(ius.last_user_seek) IS NULL AND
    MAX(ius.last_user_scan) IS NULL AND
    MAX(ius.last_user_lookup) IS NULL AND
    MAX(ius.last_user_update) IS NULL
ORDER BY 
    t.name;
	
----Table view of read/write and Tables not being used----
SELECT 
    t.name AS TableName,
    MAX(ius.last_user_seek) AS LastSeekTime,
    MAX(ius.last_user_scan) AS LastScanTime,
    MAX(ius.last_user_lookup) AS LastLookupTime,
    MAX(ius.last_user_update) AS LastUpdateTime
FROM 
    sys.tables t
LEFT JOIN 
    sys.indexes i ON t.object_id = i.object_id
LEFT JOIN 
    sys.dm_db_index_usage_stats ius 
    ON ius.object_id = i.object_id 
    AND ius.index_id = i.index_id 
    AND ius.database_id = DB_ID()
GROUP BY 
    t.name
ORDER BY 
    MAX(ius.last_user_update) DESC;
