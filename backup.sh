#!/bin/bash
#
# this script will run om manjaro and arch. for other distros,
# change rsync and other commands to accomodate your distro
# for daily execution create a symlink to the script in cron.daily:
# sudo ln -s /home/rob/Files/Scripts/backup.sh backup
#
# created by rob wijhenke november 2020
# v1.0   March 6 2020            initial realease
# v1.1   rev-a March 9 2023      fixed bug
# v1.1   rev-b March 19 2023     cleaned up code
# v1.2   December 21 2023        rewrite to introduce several functions
# v1.2   rev-a December 24 2023  added error handling
# v1.2   rev-b January 4 2024    added delete empty logs function
# v1.2   rev-b January 4 2024    further improved error & notification handling
# 

# Set some variables
EDITOR_CMD="kate"
RETENTION_CYCLE=10
NOTIFICATION_DURATION=4000
DATE=$(date +%Y-%m-%d_%H.%M)
SOURCE="/"
BACKUP="/mnt/nvme1n1p1/backup/"
OLDBACKUPS="/mnt/nvme1n1p1/oldbackups/"
SCRIPTS="/home/rob/Files/Scripts"
BACKUP_LOG="$SCRIPTS/backup-errors-$DATE.log"

# tell bash to exit on error
set -e

# Check if required commands are available
for cmd in rsync find notify-send $EDITOR_CMD; do
  if ! command -v $cmd &> /dev/null; then
    ERROR_MSG="Error: $cmd is not installed."
    echo "$ERROR_MSG" >> "$BACKUP_LOG"
    notify-send -t $NOTIFICATION_DURATION "$ERROR_MSG"
    exit 1
  fi
done

# Check if directories exist
for dir in $SOURCE $BACKUP $OLDBACKUPS; do
  if [ ! -d "$dir" ]; then
    ERROR_MSG="Error: Directory $dir does not exist."
    echo "$ERROR_MSG" >> "$BACKUP_LOG"
    notify-send -t $NOTIFICATION_DURATION "$ERROR_MSG"
    exit 1
  fi
done

# Notify that backup is starting
notify-send -t $NOTIFICATION_DURATION "Backup is starting..." || exit 1

# Sync source to backup
sync_source_to_backup() {
    # rsync command to backup home drive (1 TB SSD '1') recursively to /mnt/nvme1n1p1 (1 TB SSD '2') 
    # while copying deleted files to /mnt/nvme1n1p1/oldbackups
    # each oldbackups entry is in a timestamped directory
    ERROR_OUTPUT=$(sudo rsync -a -v --progress --backup-dir="$OLDBACKUPS/$DATE" --delete -b -s --include-from "$SCRIPTS/backupinclude.txt" --exclude-from "$SCRIPTS/backupexclude.txt" $SOURCE "$BACKUP" 2>&1) || {
        ERROR_MSG="rsync failed with exit code $?. Check the log file for details."
        echo "$ERROR_OUTPUT" >> "$BACKUP_LOG"
        notify-send -t $NOTIFICATION_DURATION "$ERROR_MSG"
        exit 1
    }
}

# Handle backup logs
handle_backup_logs() {
    if [ -s $BACKUP_LOG ]; then
        $EDITOR_CMD $BACKUP_LOG
    fi
    if [ -f $BACKUP_LOG ]; then
        notify-send -t $NOTIFICATION_DURATION "No errors occurred during backup. Deleting log file."
        rm $BACKUP_LOG
    fi
    notify-send -t $NOTIFICATION_DURATION "Backup finished"
}

# Delete old backup directories
delete_old_backup_directories() {
    find $OLDBACKUPS/* -type d -ctime +$RETENTION_CYCLE -exec sudo rm -rf {} \; || {
        notify-send -t $NOTIFICATION_DURATION "Failed to delete old backups with exit code $?" || echo "Failed to delete old backups with exit code $?" >> "$BACKUP_LOG"
        exit 1
    }
}

# Execute the functions
sync_source_to_backup
handle_backup_logs
delete_old_backup_directories
