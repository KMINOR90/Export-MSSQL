---Login names, LoginType, Role Name. Role name, Type, Creation Date, Modify_date.

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