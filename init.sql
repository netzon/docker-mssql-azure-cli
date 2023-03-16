--- Warning! This file only contains sample credentials. Do not use in production!
--- Find backup of created keys at /usr/src/app/certs within the container image.

USE master;
GO

PRINT 'Initializing app Database...';
IF (SELECT count(*) FROM sys.databases WHERE name = '__DB_NAME__') = 0
BEGIN
  CREATE DATABASE __DB_NAME__;
END
GO

PRINT 'Initializing TDE...';
IF (SELECT count(*) as KEYS FROM sys.symmetric_keys WHERE name='##MS_DatabaseMasterKey##') = 0
BEGIN
  PRINT 'Create symmetric key for DMS...'
  CREATE MASTER KEY ENCRYPTION BY PASSWORD = '__DB_KEY_ENCRYPTION_PASSWORD__';

  SELECT name KeyName,
    symmetric_key_id KeyID,
    key_length KeyLength,
    algorithm_desc KeyAlgorithm
  FROM sys.symmetric_keys;

  PRINT 'Create certificate based on DMS...'
  CREATE CERTIFICATE TdeCert WITH SUBJECT = 'TDE certificate';

  -- Check certficate presence
  SELECT name CertName,
    certificate_id CertID,
    pvt_key_encryption_type_desc EncryptType,
    issuer_name Issuer
  FROM sys.certificates
  WHERE issuer_name = 'TDE certificate';

  PRINT 'Backing up keys to /usr/src/app/certs...';
  
  BACKUP SERVICE MASTER KEY 
    TO FILE = '/usr/src/app/certs/SvcMasterKey.key' 
    ENCRYPTION BY PASSWORD = '__DB_KEY_ENCRYPTION_PASSWORD__';

  BACKUP MASTER KEY 
    TO FILE = '/usr/src/app/certs/DbMasterKey.key'
    ENCRYPTION BY PASSWORD = '__DB_KEY_ENCRYPTION_PASSWORD__';

  BACKUP CERTIFICATE TdeCert 
    TO FILE = '/usr/src/app/certs/TdeCert.cer'
    WITH PRIVATE KEY(
      FILE = '/usr/src/app/certs/TdeCert.key',
      ENCRYPTION BY PASSWORD = '__DB_KEY_ENCRYPTION_PASSWORD__'
    );
END
GO

-- Install encryption for app database if not yet installed & enable encryption on db
USE __DB_NAME__;
GO

IF (SELECT count(*) as key_count FROM sys.dm_database_encryption_keys WHERE  DB_NAME(database_id) = '__DB_NAME__') = 0
BEGIN

  -- Enable Database Level Encryption (Transparent Database Encryption)
  PRINT 'Creates an encryption key that is used for database level encryption (TDE)...';
  CREATE DATABASE ENCRYPTION KEY WITH ALGORITHM = AES_256 ENCRYPTION BY SERVER CERTIFICATE TdeCert;
  SELECT DB_NAME(database_id) DbName,
    encryption_state EncryptState,
    key_algorithm KeyAlgorithm,
    key_length KeyLength,
    encryptor_type EncryptType
  FROM sys.dm_database_encryption_keys;

  PRINT 'Enabling encryption for app database... Required the database encryption key to be created first.';
  ALTER DATABASE __DB_NAME__ SET ENCRYPTION ON;

  -- Enable Column Level Encryption
  PRINT 'Create master key for app database used for other assymetric keys...';
  CREATE MASTER KEY ENCRYPTION BY PASSWORD = '__DB_KEY_ENCRYPTION_PASSWORD__';
  PRINT 'Creating certificate for app database used for column level encryption...';
  CREATE CERTIFICATE TdeAppCert WITH SUBJECT = 'TDE App Certificate';
  PRINT 'Creating symmetric key for column level encryption...';
  CREATE SYMMETRIC KEY TdeKey WITH ALGORITHM = AES_256 ENCRYPTION BY CERTIFICATE TdeAppCert;
  SELECT name KeyName, 
      symmetric_key_id KeyID, 
      key_length KeyLength, 
      algorithm_desc KeyAlgorithm
  FROM sys.symmetric_keys;

  -- Backup App DB Master Key
  BACKUP MASTER KEY 
    TO FILE = '/usr/src/app/certs/AppDbMasterKey.key'
    ENCRYPTION BY PASSWORD = '__DB_KEY_ENCRYPTION_PASSWORD__';

  -- Backup App DB Certificate
  BACKUP CERTIFICATE TdeAppCert 
    TO FILE = '/usr/src/app/certs/TdeAppCert.cer'
    WITH PRIVATE KEY(
      FILE = '/usr/src/app/certs/TdeAppCert.key',
      ENCRYPTION BY PASSWORD = '__DB_KEY_ENCRYPTION_PASSWORD__'
    );
END
GO

-- Check encryption states
SELECT DB_NAME(database_id) DbName,
  encryption_state EncryptState,
  key_algorithm KeyAlgorithm,
  key_length KeyLength,
  encryptor_type EncryptType
FROM sys.dm_database_encryption_keys;