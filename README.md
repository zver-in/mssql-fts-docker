# mssql-fts-docker

Custom SQL Server 2017 Docker image based on the official Microsoft image with:

- `mssql-server-fts` preinstalled
- automatic `COMPATIBILITY_LEVEL = 130` for all user databases

This setup is intended as a practical approximation of SQL Server 2016 behavior for local development and testing while still using an official Linux container image.

The image is configured to run as the non-root `mssql` user and stores SQL Server service files under `/var/opt/mssql`, not under the filesystem root.

## What's Included

- Base image: `mcr.microsoft.com/mssql/server:2017-latest`
- Full-Text Search via `mssql-server-fts`
- `sqlcmd` via `mssql-tools`
- Custom entrypoint that waits for SQL Server to start and sets `COMPATIBILITY_LEVEL = 130` on all user databases
- `HOME=/var/opt/mssql` and `WORKDIR /var/opt/mssql` so SQL Server does not try to create `/.system`

System databases are not modified.

## Why Compatibility Level 130

`130` is the compatibility level used by SQL Server 2016. This does not make SQL Server 2017 identical to SQL Server 2016, but it helps align database behavior more closely with a SQL Server 2016 production environment.

## Build

```bash
docker build -t mssql-fts .
```

If you want a local versioned build, tag it explicitly:

```bash
docker build -t ghcr.io/<owner>/mssql-fts-docker:1.0.0 .
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

The container does not need to run as `root` and does not require write permissions on `/`.

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

## Non-Root Startup

SQL Server may try to create a hidden `/.system` directory if the process starts without a writable home directory. This image avoids that by setting:

- `HOME=/var/opt/mssql`
- `WORKDIR /var/opt/mssql`

The entrypoint also ensures `${HOME}/.system` exists before starting `sqlservr`, so the container starts cleanly in CI and in Testcontainers without granting write access to `/` or switching to a privileged user.

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

- On pushes to `main` or `master`, it publishes the branch tag, a short commit tag such as `sha-abc1234`, and also `latest` for the default branch
- On pushes of tags matching `v*`, it publishes release tags such as `v1.0.0`, `1.0.0`, and `1.0`
- The workflow can also be started manually with `workflow_dispatch`

To publish, GitHub Actions must be enabled for the repository. Authentication uses the built-in `GITHUB_TOKEN` with `packages: write` permission.

## Image Versioning

The published image is versioned by git tags, not by a version hardcoded in [Dockerfile](/Users/ivan/src/mssql-fts-docker/Dockerfile).

Recommended release format:

- `vMAJOR.MINOR.PATCH`, for example `v1.0.0`

When you push a release tag such as `v1.2.3`, the workflow publishes these image tags:

- `ghcr.io/<owner>/<repo>:v1.2.3`
- `ghcr.io/<owner>/<repo>:1.2.3`
- `ghcr.io/<owner>/<repo>:1.2`

On regular branch pushes, the workflow also publishes:

- the branch name, for example `main`
- a short immutable commit tag, for example `sha-abc1234`
- `latest` on the default branch

Release flow:

```bash
git tag v1.0.0
git push origin v1.0.0
```

After that, the image can be pulled by the release tag:

```bash
docker pull ghcr.io/<owner>/<repo>:1.0.0
```

This approach keeps release versions stable and human-readable while still providing an immutable commit-based tag for every published build.

## Limitations

- This image uses SQL Server 2017, not SQL Server 2016.
- `COMPATIBILITY_LEVEL = 130` improves compatibility, but it does not fully reproduce SQL Server 2016 engine behavior.
- If a new user database appears after startup, the container will update its compatibility level on the next background check.
