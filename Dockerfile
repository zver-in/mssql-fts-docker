# Base SQL Server 2017 image
FROM mcr.microsoft.com/mssql/server:2017-latest

# Root privileges are required to install packages
USER root

RUN set -eux; \
    . /etc/os-release; \
    ubuntu_version="${VERSION_ID}"; \
    major_version="${ubuntu_version%%.*}"; \
    \
    # Update the package list and install tools required to add the Microsoft repository
    apt-get update; \
    apt-get install -y --no-install-recommends curl ca-certificates gnupg; \
    \
    # Add the GPG key and SQL Server 2017 repository matching the base OS
    curl -fsSL https://packages.microsoft.com/keys/microsoft.asc \
      | gpg --dearmor -o /usr/share/keyrings/microsoft-prod.gpg; \
    curl -fsSL "https://packages.microsoft.com/config/ubuntu/${ubuntu_version}/mssql-server-2017.list" \
      -o /etc/apt/sources.list.d/mssql-server-2017.list; \
    curl -fsSL "https://packages.microsoft.com/config/ubuntu/${major_version}/prod.list" \
      -o /etc/apt/sources.list.d/msprod.list; \
    sed -i 's|^deb \[|deb [signed-by=/usr/share/keyrings/microsoft-prod.gpg |' \
      /etc/apt/sources.list.d/mssql-server-2017.list \
      /etc/apt/sources.list.d/msprod.list; \
    \
    # Install Full-Text Search and sqlcmd
    apt-get update; \
    ACCEPT_EULA=Y apt-get install -y --no-install-recommends mssql-server-fts mssql-tools; \
    \
    # Remove temporary packages used only during image build
    apt-get purge -y --auto-remove curl gnupg; \
    \
    # Clean apt metadata and caches to reduce image size
    apt-get clean; \
    rm -rf /var/lib/apt/lists/* /var/cache/apt/archives/*

COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
COPY set-compatibility-level.sh /usr/local/bin/set-compatibility-level.sh

RUN chmod +x /usr/local/bin/docker-entrypoint.sh /usr/local/bin/set-compatibility-level.sh

# Switch back to the default SQL Server user
USER mssql

ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
