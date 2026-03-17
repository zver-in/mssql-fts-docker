# mssql-fts-docker

Custom SQL Server 2017 Docker image based on the official Microsoft image with:

- `mssql-server-fts` preinstalled
- automatic `COMPATIBILITY_LEVEL = 130` for all user databases

This setup is intended as a practical approximation of SQL Server 2016 behavior for local development and testing while still using an official Linux container image.

## What's Included

- Base image: `mcr.microsoft.com/mssql/server:2017-latest`
- Full-Text Search via `mssql-server-fts`
- `sqlcmd` via `mssql-tools`
- Custom entrypoint that waits for SQL Server to start and sets `COMPATIBILITY_LEVEL = 130` on all user databases

System databases are not modified.

## Why Compatibility Level 130

`130` is the compatibility level used by SQL Server 2016. This does not make SQL Server 2017 identical to SQL Server 2016, but it helps align database behavior more closely with a SQL Server 2016 production environment.

## Build

```bash
docker build -t mssql-fts .
```

## Run

Example startup command:

```bash
docker run -d \
  --name mssql-fts \
  -e ACCEPT_EULA=Y \
  -e MSSQL_SA_PASSWORD='YourStrong!Passw0rd' \
  -p 1433:1433 \
  mssql-fts
```

If you need persistent data:

```bash
docker run -d \
  --name mssql-fts \
  -e ACCEPT_EULA=Y \
  -e MSSQL_SA_PASSWORD='YourStrong!Passw0rd' \
  -p 1433:1433 \
  -v mssql_data:/var/opt/mssql \
  mssql-fts
```

The compatibility adjustment script supports both `MSSQL_SA_PASSWORD` and `SA_PASSWORD`, but `MSSQL_SA_PASSWORD` is the recommended variable to pass at container startup.

## Verify Full-Text Search

```sql
SELECT FULLTEXTSERVICEPROPERTY('IsFullTextInstalled') AS IsFullTextInstalled;
```

Expected value: `1`.

Example:

```bash
docker exec -it mssql-fts /opt/mssql-tools/bin/sqlcmd \
  -S localhost \
  -U sa \
  -P 'YourStrong!Passw0rd' \
  -Q "SELECT FULLTEXTSERVICEPROPERTY('IsFullTextInstalled') AS IsFullTextInstalled;"
```

## Verify Compatibility Level

To check user database compatibility levels:

```sql
SELECT name, compatibility_level
FROM sys.databases
WHERE database_id > 4
ORDER BY name;
```

Expected value for user databases: `130`.

Example:

```bash
docker exec -it mssql-fts /opt/mssql-tools/bin/sqlcmd \
  -S localhost \
  -U sa \
  -P 'YourStrong!Passw0rd' \
  -Q "SELECT name, compatibility_level FROM sys.databases WHERE database_id > 4 ORDER BY name;"
```

## Requirements

- Docker
- At least 2 GB of RAM for the SQL Server container
- A strong `MSSQL_SA_PASSWORD` that satisfies SQL Server password policy

## Publishing to GitHub Container Registry

The repository includes the workflow [`.github/workflows/publish.yml`](/Users/ivan/src/mssql-fts-docker/.github/workflows/publish.yml), which publishes the image to `ghcr.io/<owner>/<repo>`.

- On pushes to `main` or `master`, it publishes the branch tag and also `latest` for the default branch
- On pushes of tags matching `v*`, it publishes release tags such as `v1.0.0`, `1.0.0`, and `1.0`
- The workflow can also be started manually with `workflow_dispatch`

To publish, GitHub Actions must be enabled for the repository. Authentication uses the built-in `GITHUB_TOKEN` with `packages: write` permission.

## Limitations

- This image uses SQL Server 2017, not SQL Server 2016.
- `COMPATIBILITY_LEVEL = 130` improves compatibility, but it does not fully reproduce SQL Server 2016 engine behavior.
- If a new user database appears after startup, the container will update its compatibility level on the next background check.
