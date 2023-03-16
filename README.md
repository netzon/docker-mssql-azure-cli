# Introduction

__Warning: This is not a production-ready solution. It is intended for development purposes only. The `.env.dev` file is not included in this release! Only used by maintainers. Create your own!__

Building the image.

```bash
docker build -t "netzon/mssql-azure-cli:mssql-2022-azure-cli-2.46" .
```

Running as a docker compose project.

```bash
# preview the compose file with .env.dev values
docker-compose --env-file .env.dev convert

# start docker-compose but rebuild
docker-compose --env-file .env.dev up --build

# start docker-compose but rebuild in detached mode
docker-compose --env-file .env.dev up --build -d

# stop docker-compose along with volumes
docker-compose --env-file .env.dev down -v
```

## Configuration

Example content of an `.env` file:

```bash
MSSQL_SA_PASSWORD="p@ssw0rd!"
ACCEPT_EULA="Y"
DB_NAME="myapplicationdb"
DB_KEY_ENCRYPTION_PASSWORD="p@ssw0rd!"
AZ_PASSWORD="client-secret"
AZ_USERNAME="app-client-id"
AZ_TENANT="azure-tenant-id"
```

This is a `Dockerfile` spec that allows for initializing the `mssql` database for [TDE](https://learn.microsoft.com/en-us/sql/relational-databases/security/encryption/transparent-data-encryption) & [Always Encrypted](https://learn.microsoft.com/en-us/sql/connect/ado-net/sql/sqlclient-support-always-encrypted). In addition to the original master database that is created on init, an additional database `$DB_NAME` with `ENCRYPTION` set to `ON` is also created. Certificates are then created within the container at `/usr/src/app/certs` on init.

## Always Encrypted

[Always Encrypted](https://learn.microsoft.com/en-us/sql/connect/ado-net/sql/sqlclient-support-always-encrypted) is a feature that enables encryption of sensitive data in the database at the column level, while keeping the data encrypted at rest, in transit, and in use within client applications. With Always Encrypted, the data is encrypted before it leaves the client application, and the keys used to encrypt the data are stored outside of the database. This means that even database administrators cannot access the unencrypted data. Always Encrypted is suitable for protecting sensitive data such as credit card numbers, social security numbers, and other Personally Identifiable Information (PII).

### Key Generation

- https://learn.microsoft.com/en-us/sql/relational-databases/security/encryption/configure-always-encrypted-keys-using-powershell?view=sql-server-ver16
- https://khaledelsheikh.medium.com/configuring-always-encrypted-on-azure-sql-by-using-azure-key-vault-and-entity-framework-core-aae687ff2c63

## Transparent Data Encryption (TDE):
    
[TDE](https://learn.microsoft.com/en-us/sql/relational-databases/security/encryption/transparent-data-encryption) is a feature that encrypts the entire database, including all its data and log files, at the file level. With TDE, the data is encrypted while it is at rest on the disk, but it is decrypted when it is loaded into memory for processing. TDE is suitable for protecting the entire database from unauthorized access in case of physical theft of disks or backups.

## Difference between Always Encrypted and TDE:

* Always Encrypted provides encryption at the column level, while TDE provides encryption at the file level.
* Always Encrypted is designed to protect sensitive data while it is being used within client applications, while TDE protects the entire database from unauthorized access at rest.
* Always Encrypted requires changes to client applications to support encryption, while TDE can be implemented without requiring changes to client applications.