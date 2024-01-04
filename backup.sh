#!/bin/bash
#
# rsync command to backup home drive (1 TB SSD '1') recursively to /mnt/nvme1n1p1 (1 TB SSD '2') 
# while copying deleted files to /mnt/nvme1n1p1/oldbackups
# each oldbackups entry is in a timestamped directory
#
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
# v1.2   rev-b January 4 2024    improved notification handling
# 

# Set some variables
OLDBACKUPS="/mnt/nvme1n1p1/oldbackups/"
SOURCE="/"
BACKUP="/mnt/nvme1n1p1/backup/"
SCRIPTS="/home/rob/Files/Scripts"
RETENTION_CYCLE=14
DATE=$(date +%Y-%m-%d_%H.%M)
BACKUP_LOG="$SCRIPTS/backup-errors-$DATE.log"
NOTIFICATION_DURATION=4000

# Notify that backup is starting
notify-send -t $NOTIFICATION_DURATION "Backup is starting..."

# tell bash to exit on error
set -e

# Sync files
sync_files() {
    sudo rsync -a -v --progress --backup-dir="$OLDBACKUPS/$DATE" --delete -b -s --include-from "$SCRIPTS/backupinclude.txt" --exclude-from "$SCRIPTS/backupexclude.txt" $SOURCE "$BACKUP" 2>"$BACKUP_LOG" || {
        notify-send -t $NOTIFICATION_DURATION "rsync failed with exit code $?" 
        exit 1
    }
}

# Handle log files
handle_logs() {
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
delete_old_backups() {
    find $OLDBACKUPS/* -type d -ctime +$RETENTION_CYCLE -exec sudo rm -rf {} \; || {
        notify-send -t $NOTIFICATION_DURATION "Failed to delete old backups with exit code $?" 
        exit 1
    }
}

# Execute the functions
sync_files

if [ -s $BACKUP_LOG ]
then
    handle_logs
else
    delete_old_backups
    handle_logs
fi
