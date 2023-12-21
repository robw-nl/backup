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
# v1.1 rev-a march 9 2023
# v1.1 rev-b march 19 2023
# v1.2  December 21 2023 rewrite to introduce several functions
#

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
    sudo rsync -a -v --progress --backup-dir="$OLDBACKUPS/$DATE" --delete -b -s --include-from "$SCRIPTS/backupinclude.txt" --exclude-from "$SCRIPTS/backupexclude.txt" $SOURCE "$BACKUP" 2>"$BACKUP_LOG"
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
    find $OLDBACKUPS/* -type d -ctime +$RETENTION_CYCLE -exec sudo rm -rf {} \;
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
