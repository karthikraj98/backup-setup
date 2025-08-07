#!/bin/bash
set -e

# === Configuration ===
STORE_NAME="store1"
DB_NAME="odoo17-server1"
DB_USER="odoo"
PGPASSWORD="admin"
export PGPASSWORD

BACKUP_BASE="/home/odoo/backups/${STORE_NAME}"
DATE=$(date +%Y-%m-%d_%H-%M-%S)
REMOTE_USER="odoo"
REMOTE_HOST="172.31.84.29"  # central server IP

mkdir -p "${BACKUP_BASE}/dumps" "${BACKUP_BASE}/base" "${BACKUP_BASE}/wal"

# --- Dump file ---
DUMP_NAME="${DB_NAME}_${DATE}.dump"
pg_dump -Fc -U "$DB_USER" "$DB_NAME" -f "${BACKUP_BASE}/dumps/$DUMP_NAME"

# --- Base Backup ---
rm -rf "${BACKUP_BASE}/base"/*
pg_basebackup -U "$DB_USER" -D "${BACKUP_BASE}/base" -F tar -X fetch -z -P --wal-method=fetch

# --- Archive WALs ---
WAL_ARCHIVE_SRC="${BACKUP_BASE}/wal"
mkdir -p "$WAL_ARCHIVE_SRC"

# --- Push to central ---
if scp -r "${BACKUP_BASE}/" "$REMOTE_USER@$REMOTE_HOST:/home/odoo/central_backups/"; then
    echo "✅ Backup & WALs uploaded successfully. Cleaning up local WAL files..."
    rm -f "${WAL_ARCHIVE_SRC}"/*
else
    echo "❌ SCP failed — keeping WAL files for retry."
    exit 1
fi
