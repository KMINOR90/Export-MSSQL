---This SQL Script allows you to pull Transactional Logs, Size, last log backup, and database---

SELECT
    db.name AS DatabaseName,
    mf.name AS FileName,
    mf.type_desc AS FileType,
    CAST(mf.size AS BIGINT) * 8 / 1024 AS FileSizeMB,  -- Size in MB (8 KB per page)
    CAST(mf.max_size AS BIGINT) * 8 / 1024 AS MaxSizeMB,  -- Max Size in MB
    CAST(mf.growth AS BIGINT) * 8 / 1024 AS GrowthMB,    -- Growth in MB
    mf.physical_name AS FilePath,
    MAX(b.backup_finish_date) AS LastLogBackupDate -- Get the last backup date
FROM 
    sys.databases db
JOIN 
    sys.master_files mf ON db.database_id = mf.database_id
LEFT JOIN 
    msdb.dbo.backupset b ON db.name = b.database_name
    AND b.type = 'L' -- 'L' for log backups
WHERE 
    mf.type = 1  -- Type = 1 means it's a LOG file (Transaction Log)
GROUP BY 
    db.name, mf.name, mf.type_desc, mf.size, mf.max_size, mf.growth, mf.physical_name
ORDER BY 
    db.name;