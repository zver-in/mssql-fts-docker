#!/usr/bin/env bash
set -euo pipefail

sa_password="${MSSQL_SA_PASSWORD:-${SA_PASSWORD:-}}"

if [[ -z "${sa_password}" ]]; then
    echo "MSSQL_SA_PASSWORD or SA_PASSWORD is not set; skipping compatibility level adjustment." >&2
    exit 0
fi

if [[ -x /opt/mssql-tools/bin/sqlcmd ]]; then
    sqlcmd_bin=/opt/mssql-tools/bin/sqlcmd
    sqlcmd_tls_args=()
elif [[ -x /opt/mssql-tools18/bin/sqlcmd ]]; then
    sqlcmd_bin=/opt/mssql-tools18/bin/sqlcmd
    sqlcmd_tls_args=(-C)
else
    echo "sqlcmd was not found; skipping compatibility level adjustment." >&2
    exit 0
fi

wait_for_sql_server() {
    local retries=60

    until "${sqlcmd_bin}" "${sqlcmd_tls_args[@]}" -S localhost -U sa -P "${sa_password}" -Q "SELECT 1" >/dev/null 2>&1; do
        retries=$((retries - 1))
        if [[ "${retries}" -le 0 ]]; then
            echo "SQL Server did not become ready in time; skipping compatibility level adjustment." >&2
            return 1
        fi
        sleep 2
    done
}

apply_compatibility_level() {
    "${sqlcmd_bin}" "${sqlcmd_tls_args[@]}" -S localhost -U sa -P "${sa_password}" -b -Q "
SET NOCOUNT ON;
DECLARE @sql nvarchar(max) = N'';

SELECT @sql = @sql + N'
IF EXISTS (
    SELECT 1
    FROM sys.databases
    WHERE name = N''' + REPLACE(name, '''', '''''') + N'''
      AND compatibility_level <> 130
)
BEGIN
    ALTER DATABASE ' + QUOTENAME(name) + N' SET COMPATIBILITY_LEVEL = 130;
END;'
FROM sys.databases
WHERE database_id > 4;

IF LEN(@sql) > 0
BEGIN
    EXEC sys.sp_executesql @sql;
END;"
}

wait_for_sql_server || exit 0
apply_compatibility_level

while true; do
    sleep 60
    apply_compatibility_level || true
done
