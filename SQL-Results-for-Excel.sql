--script is for Exporting logins and permissions

SELECT 
    sp.name AS LoginName,
    sp.type_desc AS LoginType,
    sl.dbname AS DatabaseName,
    dp.permission_name AS Permission
FROM 
    sys.server_principals sp
LEFT JOIN 
    sys.database_permissions dp ON sp.principal_id = dp.grantee_principal_id
LEFT JOIN 
    sys.syslogins sl ON sp.sid = sl.sid
ORDER BY 
    sp.name, dp.permission_name;
	
	
--Exporting Permissions for Each User--

SELECT 
    dp.name AS UserName,
    dp.type_desc AS UserType,
    dp2.permission_name AS PermissionType,
    dp2.state_desc AS PermissionState
FROM 
    sys.database_principals dp
LEFT JOIN 
    sys.database_permissions dp2 ON dp.principal_id = dp2.grantee_principal_id
ORDER BY 
    dp.name, dp2.permission_name;
	
--SQL Scipt to Pull All Database Information/ The error message indicates that the column database_id does not exist in the sys.database_files view.
--In SQL Server, sys.database_files is typically used within the context of a specific database, and the column database_id is not present in this view. 
--Instead, you generally use sys.master_files in the master database when you need information about all databases and their files.

SELECT 
    db.name AS DatabaseName,
    db.state_desc AS DatabaseState,
    db.recovery_model_desc AS RecoveryModel,
    db.compatibility_level AS CompatibilityLevel,
    mf.name AS LogicalFileName,
    mf.physical_name AS PhysicalFileName,
    mf.type_desc AS FileType,
    mf.size / 128 AS FileSizeMB,
    mf.max_size / 128 AS MaxSizeMB,
    mf.growth / 128 AS GrowthMB,
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

--SQL Script to Pull Server Accounts
