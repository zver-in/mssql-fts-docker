#!/usr/bin/env bash
set -eu

sa_password="${MSSQL_SA_PASSWORD:-${SA_PASSWORD:-}}"
sqlcmd_bin="/opt/mssql-tools/bin/sqlcmd"

if [[ -z "${sa_password}" ]]; then
    echo "MSSQL_SA_PASSWORD or SA_PASSWORD is not set; skipping compatibility level adjustment." >&2
    exit 0
fi

if [[ ! -x "${sqlcmd_bin}" ]]; then
    echo "sqlcmd was not found at ${sqlcmd_bin}; skipping compatibility level adjustment." >&2
    exit 0
fi

query="
SET NOCOUNT ON;
DECLARE @sql nvarchar(max) = N'';

SELECT @sql = @sql + N'ALTER DATABASE ' + QUOTENAME(name) + N' SET COMPATIBILITY_LEVEL = 130;'
FROM sys.databases
WHERE database_id > 4
  AND compatibility_level <> 130;

IF LEN(@sql) > 0
BEGIN
    EXEC sys.sp_executesql @sql;
END;"

while true; do
    "${sqlcmd_bin}" -S localhost -U sa -P "${sa_password}" -b -Q "${query}" >/dev/null 2>&1 || true
    sleep 60
done
