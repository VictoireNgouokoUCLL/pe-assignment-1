#!/bin/bash
SRC_DIR="/etc"
BACKUP_ROOT="/backup"
RETENTION_DAYS=7


TIMESTAMP=$(date +%Y%m%d_%H%M%S)
DEST_DIR="$BACKUP_ROOT/$TIMESTAMP"
LOG_FILE="$BACKUP_ROOT/backup.log"


echo "=== Backup started at $(date) ===" >> "$LOG_FILE"

mkdir -p "$DEST_DIR"

rsync -a --delete "$SRC_DIR/" "$DEST_DIR/" >> "$LOG_FILE" 2>&1
RSYNC_EXIT=$?
if [ $RSYNC_EXIT -eq 0 ] || [ $RSYNC_EXIT -eq 23 ]; then
echo "Rsync completed successfully (exit code: $RSYNC_EXIT)" >> "$LOG_FILE"
else
echo "Rsync encountered a critical error (exit code: $RSYNC_EXIT)" >> "$LOG_FILE"
fi


touch "$DEST_DIR"

echo "Cleaning up backups older than $RETENTION_DAYS days..." >> "$LOG_FILE"
find "$BACKUP_ROOT" -mindepth 1 -maxdepth 1 -type d -mtime +$RETENTION_DAYS -print -exec rm -rf {} + >> "$LOG_FILE" 2>&1
echo "=== Backup finished at $(date) ===" >> "$LOG_FILE"

