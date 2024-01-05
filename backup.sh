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
# v1.2   December 21 2023        refactored introducing functions
# v1.2   rev-a December 24 2023  added error handling
# v1.2   rev-b January 3 2024    added delete empty logs function
# v1.2   rev-b January 3 2024    improved error & notification handling
# v1.3         January 5 2024    full refactoring as the code became too
#                                complex. added configuration file and
#                                re-wrote error handling en program flow
#

set -e
set -u

# Configuration - change location appropriately
CONFIG_FILE="/home/rob/Files/Scripts/backup.conf"

# Log errors log file and on screen; progress only on screen
log_and_notify() {
  local message="$1"
  local isError="$2"
  notify-send -t $NOTIFICATION_DURATION "$message"
  if [ "$isError" = true ]; then
    printf "%s\n" "$message" >> "$BACKUP_LOG"
  fi
}

# Check if required commands are installed
check_commands() {
    for cmd in rsync find notify-send $EDITOR_CMD; do
        if ! command -v $cmd &> /dev/null; then
            log_and_notify "Error: $cmd is not installed." true "$cmd" || exit 1
        fi
    done
}

# Check if directories exist
check_directories() {
    local source_dir="$1"
    local backup_dir="$2"
    local old_backups_dir="$3"
    for dir in $source_dir $backup_dir $old_backups_dir; do
        if [ ! -d "$dir" ]; then
            log_and_notify "Error: Directory $dir does not exist." true
            return 1
        fi
    done
    return 0
}

# Execute the backup
execute_backup() {
    local source_dir="$1"
    local backup_dir="$2"
    local old_backups_dir="$3"
    local date="$4"
    local scripts_dir="$5"
    local backup_log="$6"
    sudo rsync -a --progress --backup-dir="$old_backups_dir/$date" --delete -b -s --include-from "$scripts_dir/backupinclude.txt" --exclude-from "$scripts_dir/backupexclude.txt" $source_dir "$backup_dir" 2>> "$backup_log" || {
        local exit_status=$?
        log_and_notify "rsync failed with exit code $exit_status. Check the log file for details." true "rsync"
        return 1
    }
    return 0
}

# Deal with errors and notifications; keep only log files with errors
handle_backup_logs() {
    if [ -s $BACKUP_LOG ]; then
        $EDITOR_CMD $BACKUP_LOG
        log_and_notify "Errors occurred during backup. Check the log file." true
    else
        if [ -f $BACKUP_LOG ]; then
            notify-send -t $NOTIFICATION_DURATION "No errors occurred during backup"
            rm $BACKUP_LOG
        fi
        log_and_notify "Backup finished" false
    fi
}

# Main
if [ -f "$CONFIG_FILE" ]; then
    source "$CONFIG_FILE"
else
    printf "Configuration file not found at %s\n" "$CONFIG_FILE"
    exit 1
fi

check_commands
if ! check_directories $SOURCE $BACKUP $OLDBACKUPS; then
    exit 1
fi
log_and_notify "Backup is starting..." false
if ! execute_backup $SOURCE $BACKUP $OLDBACKUPS $DATE $SCRIPTS $BACKUP_LOG; then
    exit 1
fi
handle_backup_logs
