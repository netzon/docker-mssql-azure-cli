#!/bin/bash
# set -uxo pipefail
set -uo pipefail

contains_forward_slash() {
    local string="$1"

    if [[ $string == *"/"* ]]; then
        echo "true"
    else
        echo "false"
    fi
}

if [ $(contains_forward_slash "$DB_KEY_ENCRYPTION_PASSWORD") == "true" ]; then
    echo "Error: DB_KEY_ENCRYPTION_PASSWORD cannot contain forward slash (/)"
    kill -9 $(ps aux | grep 'sqlservr' | awk '{print $2}')
    exit -1;
elif [ $(contains_forward_slash "$DB_NAME") == "true" ]; then
    echo "Error: DB_NAME cannot contain forward slash (/)"
    kill -9 $(ps aux | grep 'sqlservr' | awk '{print $2}')
    exit -1;
elif [ $(contains_forward_slash "$DB_USER") == "true" ]; then
    echo "Error: DB_USER cannot contain forward slash (/)"
    kill -9 $(ps aux | grep 'sqlservr' | awk '{print $2}')
    exit -1;
elif [ $(contains_forward_slash "$DB_PASSWORD") == "true" ]; then
    echo "Error: DB_PASSWORD cannot contain forward slash (/)"
    kill -9 $(ps aux | grep 'sqlservr' | awk '{print $2}')
    exit -1;
fi

sed -i "s/__DB_KEY_ENCRYPTION_PASSWORD__/$DB_KEY_ENCRYPTION_PASSWORD/g" init.sql
sed -i "s/__DB_NAME__/$DB_NAME/g" init.sql
sed -i "s/__DB_USER__/$DB_USER/g" init.sql
sed -i "s/__DB_PASSWORD__/$DB_PASSWORD/g" init.sql

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