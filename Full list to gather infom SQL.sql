----Full Database info---First SQL code to run-----------------------
SELECT 
    db.name AS DatabaseName,
    db.state_desc AS DatabaseState,
    db.recovery_model_desc AS RecoveryModel,
    db.compatibility_level AS CompatibilityLevel,
    mf.name AS LogicalFileName,
    mf.physical_name AS PhysicalFileName,
    mf.type_desc AS FileType,
    mf.size/128 AS FileSizeMB,
    mf.max_size/128 AS MaxSizeMB,
    mf.growth/128 AS GrowthMB,
    db.owner_sid AS OwnerSID,
    dp.name AS OwnerName
FROM 
    sys.databases db
JOIN 
    sys.master_files mf
    ON db.database_id = mf.database_id
LEFT JOIN 
    sys.database_principals dp
    ON db.owner_sid = dp.sid
ORDER BY 
    db.name;
	
----Login, Role info, and Group info-2nd SQL code---------------------

-- Get logins and their associated server roles
SELECT 
    l.name AS LoginName,
    l.type_desc AS LoginType,
    r.name AS RoleName
FROM 
    sys.server_principals l
LEFT JOIN 
    sys.server_role_members rm ON l.principal_id = rm.member_principal_id
LEFT JOIN 
    sys.server_principals r ON rm.role_principal_id = r.principal_id
WHERE 
    l.type IN ('S', 'U') -- S = SQL_LOGIN, U = WINDOWS_LOGIN

-- You can add 'C' for CERTIFICATE_MAPPED_LOGIN or 'K' for ASYMMETRIC_KEY_MAPPED_LOGIN if needed.

-- Get service accounts (This typically requires checking configuration manually or through external scripts)

-- Get server roles
SELECT 
    r.name AS RoleName,
    r.type_desc AS RoleType,
    r.create_date,
    r.modify_date
FROM 
    sys.server_principals r
WHERE 
    r.type = 'R' -- R = SERVER_ROLE

-- Get Windows groups that have logins in the server
SELECT 
    l.name AS LoginName,
    l.type_desc AS LoginType
FROM 
    sys.server_principals l
WHERE 
    l.type = 'G' -- G = WINDOWS_GROUP
	
---Table, and db

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

-------Login, creation, Last modified, etc--3rd SQL code-------(Need to make adjustments that if Null move to the bottom)

-- Run this on the master database
USE master;
GO

-- Step 1: Create temp table to store database users
IF OBJECT_ID('tempdb..#UserDetails') IS NOT NULL DROP TABLE #UserDetails;
CREATE TABLE #UserDetails (
    DBName SYSNAME,
    UserName SYSNAME,
    LoginName SYSNAME NULL, -- Allow NULLs if there's no associated login
    UserTypeDesc NVARCHAR(60),
    DefaultSchemaName SYSNAME
);

-- Step 2: Cursor to loop through all user databases and collect user info
DECLARE @dbName SYSNAME;
DECLARE db_cursor CURSOR FOR
SELECT name 
FROM sys.databases 
WHERE state_desc = 'ONLINE' AND database_id > 4;

OPEN db_cursor;
FETCH NEXT FROM db_cursor INTO @dbName;

WHILE @@FETCH_STATUS = 0
BEGIN
    DECLARE @sql NVARCHAR(MAX);
    SET @sql = '
    USE [' + @dbName + '];
    INSERT INTO #UserDetails
    SELECT
        DB_NAME() AS DBName,
        dp.name AS UserName,
        sp.name AS LoginName,
        dp.type_desc AS UserTypeDesc,
        dp.default_schema_name
    FROM sys.database_principals dp
    LEFT JOIN sys.server_principals sp ON dp.sid = sp.sid
    WHERE dp.type IN (''S'', ''U'', ''G'') -- SQL user, Windows user/group
      AND dp.authentication_type IN (0, 1) -- SQL or Windows authentication
      AND dp.sid IS NOT NULL
      AND dp.name NOT LIKE ''##%'';';
    
    EXEC sp_executesql @sql;

    FETCH NEXT FROM db_cursor INTO @dbName;
END

CLOSE db_cursor;
DEALLOCATE db_cursor;

-- Step 3: Get final list with login status and last login time
-- Remove last login details if not SQL Server 2022+
SELECT
    sp.name AS LoginName,
    sp.type_desc AS LoginType,
    sp.is_disabled AS IsDisabled,
    sp.create_date AS CreatedOn,
    sp.modify_date AS LastModifiedOn,
    -- Uncomment if SQL Server 2022+
    -- sl.last_successful_logon AS LastSuccessfulLogin,
    -- sl.last_unsuccessful_logon AS LastUnsuccessfulLogin,
    ud.DBName,
    ud.UserName,
    ud.UserTypeDesc,
    ud.DefaultSchemaName
FROM sys.server_principals sp
LEFT JOIN #UserDetails ud ON sp.name = ud.LoginName
-- Uncomment if SQL Server 2022+
-- LEFT JOIN sys.dm_exec_logon_stats sl ON sp.sid = sl.sid
WHERE sp.type IN ('S', 'U', 'G') -- SQL logins, Windows users/groups
ORDER BY sp.name, ud.DBName;


-----------------4th SQL code

-- Use master context
USE master;
GO

-- Drop temp if exists
IF OBJECT_ID('tempdb..#LoginUserInfo') IS NOT NULL DROP TABLE #LoginUserInfo;
CREATE TABLE #LoginUserInfo (
    LoginName SYSNAME,
    IsDisabled BIT,
    AssociatedDBUser SYSNAME NULL,
    DatabaseName SYSNAME NULL
);

DECLARE @dbName SYSNAME;
DECLARE @sql NVARCHAR(MAX);

-- Loop through all user databases
DECLARE db_cursor CURSOR FOR
SELECT name 
FROM sys.databases 
WHERE state_desc = 'ONLINE' AND database_id > 4;

OPEN db_cursor;
FETCH NEXT FROM db_cursor INTO @dbName;

WHILE @@FETCH_STATUS = 0
BEGIN
    SET @sql = '
    USE [' + @dbName + '];
    INSERT INTO #LoginUserInfo (LoginName, IsDisabled, AssociatedDBUser, DatabaseName)
    SELECT 
        sp.name AS LoginName,
        sp.is_disabled AS IsDisabled,
        dp.name AS AssociatedDBUser,
        DB_NAME() AS DatabaseName
    FROM sys.database_principals dp
    LEFT JOIN sys.server_principals sp ON dp.sid = sp.sid
    WHERE dp.type IN (''S'', ''U'', ''G'') -- SQL/Windows user/group
      AND dp.sid IS NOT NULL
      AND dp.name NOT LIKE ''##%''
      AND sp.name IS NOT NULL;'; -- Exclude NULL logins
    
    EXEC sp_executesql @sql;

    FETCH NEXT FROM db_cursor INTO @dbName;
END

CLOSE db_cursor;
DEALLOCATE db_cursor;

-- Final results
SELECT *
FROM #LoginUserInfo
ORDER BY DatabaseName, AssociatedDBUser;