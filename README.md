# mssql-fts-docker

A SQL Server 2022 Docker image based on the official Microsoft image with the `mssql-server-fts` package preinstalled to enable Full-Text Search.

## What's Included

- Base image: `mcr.microsoft.com/mssql/server:2022-CU16-ubuntu-22.04`
- Includes the `mssql-server-fts` package
- Switches back to the default `mssql` user after installation

## Build

```bash
docker build -t mssql-fts .
```

## Run

Example container startup command:

```bash
docker run -d \
  --name mssql-fts \
  -e ACCEPT_EULA=Y \
  -e MSSQL_SA_PASSWORD='YourStrong!Passw0rd' \
  -p 1433:1433 \
  mssql-fts
```

If you need persistent data, add a volume:

```bash
docker run -d \
  --name mssql-fts \
  -e ACCEPT_EULA=Y \
  -e MSSQL_SA_PASSWORD='YourStrong!Passw0rd' \
  -p 1433:1433 \
  -v mssql_data:/var/opt/mssql \
  mssql-fts
```

## Verify Full-Text Search

After the container starts, you can verify that the component is available:

```sql
SELECT FULLTEXTSERVICEPROPERTY('IsFullTextInstalled') AS IsFullTextInstalled;
```

Expected value: `1`.

Example using `sqlcmd` inside the container:

```bash
docker exec -it mssql-fts /opt/mssql-tools18/bin/sqlcmd \
  -S localhost \
  -U sa \
  -P 'YourStrong!Passw0rd' \
  -C \
  -Q "SELECT FULLTEXTSERVICEPROPERTY('IsFullTextInstalled') AS IsFullTextInstalled;"
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

## Purpose

This repository is useful when you need a ready-to-use SQL Server 2022 container with Full-Text Search support enabled without manually installing packages on each run.
