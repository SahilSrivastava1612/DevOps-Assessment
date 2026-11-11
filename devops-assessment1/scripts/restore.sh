#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 1 ]]; then
  echo "Usage: $0 <backup-file.sql.gz>"
  exit 1
fi

BACKUP_FILE="$1"
CONTAINER="${POSTGRES_CONTAINER:-devops-assessment-postgres}"
DB_USER="${POSTGRES_USER:-devops}"
SOURCE_DB="${POSTGRES_DB:-bookings}"
RESTORE_DB="${RESTORE_DB:-bookings_restore}"

if [[ ! -f "${BACKUP_FILE}" ]]; then
  echo "ERROR: Backup file not found: ${BACKUP_FILE}"
  exit 1
fi

echo "Recreating fresh restore database: ${RESTORE_DB}"

docker exec "${CONTAINER}" \
  psql -U "${DB_USER}" -d postgres \
  -v ON_ERROR_STOP=1 \
  -c "SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE datname='${RESTORE_DB}' AND pid <> pg_backend_pid();" \
  -c "DROP DATABASE IF EXISTS ${RESTORE_DB};" \
  -c "CREATE DATABASE ${RESTORE_DB};"

echo "Restoring ${BACKUP_FILE} into ${RESTORE_DB}"

gzip -dc "${BACKUP_FILE}" | \
  docker exec -i "${CONTAINER}" \
  psql -U "${DB_USER}" -d "${RESTORE_DB}" -v ON_ERROR_STOP=1

echo "Restore completed."

echo "Source database row counts:"
docker exec "${CONTAINER}" psql -U "${DB_USER}" -d "${SOURCE_DB}" -c \
  "SELECT 'hotel_bookings' AS table_name, COUNT(*) AS row_count FROM hotel_bookings
   UNION ALL
   SELECT 'booking_events', COUNT(*) FROM booking_events;"

echo
echo "Restored database row counts:"
docker exec "${CONTAINER}" psql -U "${DB_USER}" -d "${RESTORE_DB}" -c \
  "SELECT 'hotel_bookings' AS table_name, COUNT(*) AS row_count FROM hotel_bookings
   UNION ALL
   SELECT 'booking_events', COUNT(*) FROM booking_events;"

echo
echo "Restore verification completed."
