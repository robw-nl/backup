#!/bin/bash
#
# rsync command to backup home drive recursively to /mnt/nvme1n1p1
# while copying deleted files to /mnt/nvme1n1p1/oldbackups
# each oldbackups entry is in a timestamped directory
#
# For daily execution create a symlink to the script in cron.daily:
# sudo ln -s /home/rob/Files/Scripts/backup.sh backup
#
# created by rob wijhenke november 2020
# v1.0       March 6 2023 initial realease
# v1.1 rev-a March 9 2023 fixed bug
# v1.1 rev-b March 19 2023 cleaned up code
# v1.2       December 21 2023 rewrite to introduce several functions
# v1.2 rev-a December 24 2023 added error handling
#


# Tell bash to exit on error
set -e

# Set some variables
OLDBACKUPS="/mnt/nvme1n1p1/oldbackups/"
SOURCE="/"
BACKUP="/mnt/nvme1n1p1/backup/"
SCRIPTS="/home/rob/Files/Scripts"
RETENTION_CYCLE=14
DATE=$(date +%Y-%m-%d_%H.%M)
BACKUP_LOG="$SCRIPTS/backup-errors-$DATE.log"

# Sync files
sync_files() {
    sudo rsync -a -v --progress --backup-dir="$OLDBACKUPS/$DATE" --delete -b -s --include-from "$SCRIPTS/backupinclude.txt" --exclude-from "$SCRIPTS/backupexclude.txt" $SOURCE "$BACKUP" 2>"$BACKUP_LOG" || {
        echo "rsync failed with exit code $?" >&2
        exit 1
    }
}

# Handle log files
handle_logs() {
    if [ -s $BACKUP_LOG ]
    then
        kate $BACKUP_LOG
    else
        rm $BACKUP_LOG
        notify-send "Backup finished"
    fi
}

# Delete old backup directories
delete_old_backups() {
    find $OLDBACKUPS/* -type d -ctime +$RETENTION_CYCLE -exec sudo rm -rf {} \; || {
        echo "Failed to delete old backups with exit code $?" >&2
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
