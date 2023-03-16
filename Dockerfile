FROM mcr.microsoft.com/mssql/server:2022-latest

# Switch to root user for access to apt-get install
USER root

# Install azure-cli to help with Azure Key Vault integration
RUN apt-get -y update  && \
        apt-get install -y curl && \
        curl -sL https://aka.ms/InstallAzureCLIDeb | bash

# Setup work directory
WORKDIR /usr/src/app

# Copy Init scripts
COPY . /usr/src/app

# Grant permissions for the import-data script to be executable
RUN chmod +x init.sh \
        && mkdir certs && chown -R mssql . \
        && mkdir -p /home/mssql && chown -R mssql /home/mssql

USER mssql

# Start mssql server first so that init can install data in to it.
ENTRYPOINT /usr/src/app/init.sh & /opt/mssql/bin/sqlservr