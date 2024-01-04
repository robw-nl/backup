#!/bin/bash

# Set some variables
OLDBACKUPS="/mnt/nvme1n1p1/oldbackups/"
SOURCE="/"
BACKUP="/mnt/nvme1n1p1/backup/"
SCRIPTS="/home/rob/Files/Scripts"
RETENTION_CYCLE=14
DATE=$(date +%Y-%m-%d_%H.%M)
BACKUP_LOG="$SCRIPTS/backup-errors-$DATE.log"
NOTIFICATION_DURATION=4000

# Check if required commands are available
for cmd in rsync find notify-send; do
  if ! command -v $cmd &> /dev/null; then
    notify-send -t $NOTIFICATION_DURATION "Error: $cmd is not installed."
    exit 1
  fi
done

# Check if directories exist
for dir in $SOURCE $BACKUP $OLDBACKUPS; do
  if [ ! -d "$dir" ]; then
    notify-send -t $NOTIFICATION_DURATION "Error: Directory $dir does not exist."
    exit 1
  fi
done

# Notify that backup is starting
notify-send -t $NOTIFICATION_DURATION "Backup is starting..."

# tell bash to exit on error
set -e

# Sync source to backup
sync_source_to_backup() {
    sudo rsync -a -v --progress --backup-dir="$OLDBACKUPS/$DATE" --delete -b -s --include-from "$SCRIPTS/backupinclude.txt" --exclude-from "$SCRIPTS/backupexclude.txt" $SOURCE "$BACKUP" 2>"$BACKUP_LOG" || {
        notify-send -t $NOTIFICATION_DURATION "rsync failed with exit code $?" 
        exit 1
    }
}

# Handle backup logs
handle_backup_logs() {
    if [ -s $BACKUP_LOG ]
    then
        kate $BACKUP_LOG
    else
        notify-send -t $NOTIFICATION_DURATION "No errors occurred during backup. Deleting log file."
        rm $BACKUP_LOG
        notify-send -t $NOTIFICATION_DURATION "Backup finished"
    fi
}

# Delete old backup directories
delete_old_backup_directories() {
    find $OLDBACKUPS/* -type d -ctime +$RETENTION_CYCLE -exec sudo rm -rf {} \; || {
        notify-send -t $NOTIFICATION_DURATION "Failed to delete old backups with exit code $?" 
        exit 1
    }
}

# Execute the functions
sync_source_to_backup
handle_backup_logs
delete_old_backup_directories