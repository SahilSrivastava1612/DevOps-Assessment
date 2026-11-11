#!/usr/bin/env bash
set -euo pipefail

CONTAINER="${POSTGRES_CONTAINER:-devops-assessment-postgres}"
DB_USER="${POSTGRES_USER:-devops}"
DB_NAME="${POSTGRES_DB:-bookings}"
BACKUP_DIR="${BACKUP_DIR:-backups}"

mkdir -p "${BACKUP_DIR}"

if ! docker inspect "${CONTAINER}" >/dev/null 2>&1; then
  echo "ERROR: PostgreSQL container '${CONTAINER}' does not exist."
  echo "Start the database with: docker compose up -d"
  exit 1
fi

if ! docker exec "${CONTAINER}" pg_isready -U "${DB_USER}" -d "${DB_NAME}" >/dev/null 2>&1; then
  echo "ERROR: PostgreSQL is not ready."
  exit 1
fi

TIMESTAMP="$(date '+%Y%m%d_%H%M%S')"
OUTPUT="${BACKUP_DIR}/${DB_NAME}_${TIMESTAMP}.sql.gz"

echo "Creating backup: ${OUTPUT}"

docker exec "${CONTAINER}" \
  pg_dump -U "${DB_USER}" -d "${DB_NAME}" --no-owner --no-privileges \
  | gzip > "${OUTPUT}"

if [[ ! -s "${OUTPUT}" ]]; then
  echo "ERROR: Backup file is empty."
  rm -f "${OUTPUT}"
  exit 1
fi

echo "Backup completed successfully."
ls -lh "${OUTPUT}"
