#!/bin/bash
set -uxo pipefail

sed -i "s/__DB_KEY_ENCRYPTION_PASSWORD__/$DB_KEY_ENCRYPTION_PASSWORD/g" init.sql
sed -i "s/__DB_NAME__/$DB_NAME/g" init.sql

echo "Logging in to Azure"
az login --service-principal \
    --username $AZ_USERNAME \
    --password $AZ_PASSWORD \
    --tenant $AZ_TENANT

# Allow SQL Server to start and accept connections
# sleep 30 

# Wait for the SQL Server to come up
for i in {1..50};
do
    echo "Test connection to MS SQL Server"
    /opt/mssql-tools/bin/sqlcmd -S localhost -U SA -P "$MSSQL_SA_PASSWORD" -d master -Q "SELECT getdate();"
    if [ $? -eq 0 ]
    then
        echo "Begin Initialization"
        /opt/mssql-tools/bin/sqlcmd -S localhost -U SA -P "$MSSQL_SA_PASSWORD" -d master -i init.sql

        echo "Initialization Completed. Run Test SQL Command to verify sanity."
        /opt/mssql-tools/bin/sqlcmd -S localhost -U SA -P "$MSSQL_SA_PASSWORD" -d master -Q "SELECT getdate();"
        break
    else
        echo "MS SQL Server not ready yet..."
        sleep 1
    fi
done