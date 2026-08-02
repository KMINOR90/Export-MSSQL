--This gives you Table is DB name, UserName, LoginName, UserType, DefaultSchemaName, RoleName, and MemberName



-- Run this on the master database
USE master;
GO

-- Step 1: Create temp tables to store relevant information
IF OBJECT_ID('tempdb..#UserDetails') IS NOT NULL DROP TABLE #UserDetails;
CREATE TABLE #UserDetails (
    DBName SYSNAME,
    UserName SYSNAME,
    LoginName SYSNAME NULL,
    UserTypeDesc NVARCHAR(60),
    DefaultSchemaName SYSNAME
);

IF OBJECT_ID('tempdb..#ServerRoles') IS NOT NULL DROP TABLE #ServerRoles;
CREATE TABLE #ServerRoles (
    RoleName SYSNAME,
    MemberName SYSNAME
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

-- Step 3: Get server roles
INSERT INTO #ServerRoles
SELECT 
    r.name AS RoleName,
    m.name AS MemberName
FROM sys.server_role_members rm
JOIN sys.server_principals r ON rm.role_principal_id = r.principal_id
JOIN sys.server_principals m ON rm.member_principal_id = m.principal_id;

-- Step 4: Get local publications and subscriptions, if replication is set up
IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'msdb.dbo.syspublications'))
BEGIN
    IF OBJECT_ID('tempdb..#ReplicationDetails') IS NOT NULL DROP TABLE #ReplicationDetails;
    CREATE TABLE #ReplicationDetails (
        PublicationName SYSNAME,
        SubscriptionName SYSNAME,
        DBName SYSNAME
    );

    INSERT INTO #ReplicationDetails
    SELECT 
        p.publication AS PublicationName,
        s.subscriber_db AS SubscriptionName,
        p.publisher_db AS DBName
    FROM msdb.dbo.syspublications p
    JOIN msdb.dbo.syssubscriptions s ON p.publication_id = s.publication_id;
END

-- Step 5: Select final results
SELECT
    ud.DBName,
    ud.UserName,
    ud.LoginName,
    ud.UserTypeDesc,
    ud.DefaultSchemaName
FROM #UserDetails ud
ORDER BY ud.DBName, ud.UserName;

SELECT
    sr.RoleName,
    sr.MemberName
FROM #ServerRoles sr
ORDER BY sr.RoleName, sr.MemberName;

-- Only select replication details if the table exists
IF OBJECT_ID('tempdb..#ReplicationDetails') IS NOT NULL
BEGIN
    SELECT
        rd.PublicationName,
        rd.SubscriptionName,
        rd.DBName
    FROM #ReplicationDetails rd
    ORDER BY rd.DBName, rd.PublicationName;

    DROP TABLE #ReplicationDetails;
END

-- Cleanup temp tables
DROP TABLE #UserDetails;
DROP TABLE #ServerRoles;

