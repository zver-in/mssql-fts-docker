# Base SQL Server 2022 image
FROM mcr.microsoft.com/mssql/server:2022-CU16-ubuntu-22.04

# Root privileges are required to install packages
USER root

RUN set -eux; \
    # Update the package list and install tools required to add the Microsoft repository
    apt-get update; \
    apt-get install -y --no-install-recommends curl ca-certificates gnupg; \
    \
    # Add the GPG key and SQL Server 2022 repository
    curl -fsSL https://packages.microsoft.com/keys/microsoft.asc \
      | gpg --dearmor -o /usr/share/keyrings/microsoft-prod.gpg; \
    curl -fsSL https://packages.microsoft.com/config/ubuntu/22.04/mssql-server-2022.list \
      -o /etc/apt/sources.list.d/mssql-server-2022.list; \
    sed -i 's|^deb \[|deb [signed-by=/usr/share/keyrings/microsoft-prod.gpg |' \
      /etc/apt/sources.list.d/mssql-server-2022.list; \
    \
    # Install Full-Text Search for SQL Server
    apt-get update; \
    ACCEPT_EULA=Y apt-get install -y --no-install-recommends mssql-server-fts; \
    \
    # Clean the apt cache to reduce image size
    rm -rf /var/lib/apt/lists/*

# Switch back to the default SQL Server user
USER mssql
