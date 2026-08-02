--script is for Exporting logins and permissions--

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