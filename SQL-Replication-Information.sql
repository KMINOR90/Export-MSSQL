USE [ASMTraceability];
GO

SELECT 
    name AS PublicationName,
    repl_freq AS ReplicationFrequency,
    CASE repl_freq
        WHEN 1 THEN 'Snapshot'
        WHEN 2 THEN 'Transactional'
        WHEN 3 THEN 'Merge'
        ELSE 'Unknown'
    END AS PublicationType,
    CASE status
        WHEN 0 THEN 'Inactive'
        WHEN 1 THEN 'Active'
        ELSE 'Unknown'
    END AS PublicationStatus,
    description AS PublicationDescription
FROM 
    syspublications;
GO

-----Replication information: Will provide you the PublisherDatabase and the PublicationName----

USE distribution;
GO

SELECT 
    publisher_db AS PublisherDatabase,
    publication AS PublicationName
FROM 
    MSpublications;
GO

-----Replication information: Will provide you the PblisherDatabase and the PublicationName; also a description.

USE distribution;
GO

SELECT 
    publisher_db AS PublisherDatabase,
    publication AS PublicationName,
    publisher_db + ' - ' + publication AS Description
FROM 
    MSpublications;
GO
