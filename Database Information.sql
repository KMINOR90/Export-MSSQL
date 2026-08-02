--- Designed to gather and present detailed information about databases and their associated files within a SQL Server instance--


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