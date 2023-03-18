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
# v1.1 rev-b march 18 2023
#

# set some variables
OLDBACKUPS="/mnt/nvme1n1p1/oldbackups/"
BACKUP="/mnt/nvme1n1p1/backup/"
SCRIPTS="/home/rob/Files/Scripts"
RETENTION_CYCLE=10

# sync it
sudo rsync -a -v --progress --backup-dir=$OLDBACKUPS/`date +%Y-%m-%d_%H.%M` --delete -b -s --include-from $SCRIPTS/backupinclude.txt --exclude-from $SCRIPTS/backupexclude.txt /home/rob $BACKUP 2>$SCRIPTS/backup-errors.log

# open log whenever an error was thrown
if [ -s $SCRIPTS/backup-errors.log ]
then
    kate $SCRIPTS/backup-errors.log
else
    # delete backup dirs older then n days 
    # (where n = n+1 so 5 = 6 days counting from 0)
    find $OLDBACKUPS/* -type d -ctime +$RETENTION_CYCLE -exec sudo rm -rf {} \;
    
    # open log whenever an error was thrown
    if [ -s $SCRIPTS/backup-rm-errors.log ]
    then
        kate $SCRIPTS/backup-rm-errors.log
    fi
    notify-send "Backup finished"
fi
