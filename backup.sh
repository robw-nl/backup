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
# v1.3         January 6 2024    full refactoring as the code became too complex.
#              added configuration file and re-wrote error handling en program flow
# v1.3   rev-c January 11 2024   fixed bug in error handling
# v1.3   rev-d January 12 2024   re-added old backup deletion following retension cycle
#

set -e
set -u

# Configuration - change location appropriately
CONFIG_FILE="/home/rob/Files/Scripts/backup.conf"

# Log errors log file and on screen; progress only on screen
log_and_notify() {
  local message="$1"
  local isError="$2"
  if ! notify-send -t "${NOTIFICATION_DURATION}" "${message}"; then
    printf "Failed to send desktop notification: %s\n" "${message}" >> "${BACKUP_LOG}"
  fi
  if [[ "${isError}" = true ]]; then
    printf "%s\n" "${message}" >> "${BACKUP_LOG}"
  fi
}

# Check if required commands are installed
check_commands() {
    for cmd in rsync find notify-send "${EDITOR_CMD}"; do
        if ! command -v "${cmd}" > /dev/null 2>&1; then
            log_and_notify "Error: ${cmd} is not installed." true || exit 1
        fi
    done
}

# Check if directories exist
check_directories() {
    for dir in "${SOURCE}" "${BACKUP}" "${OLD_BACKUP_DIR}"; do
        if [[ ! -d "${dir}" ]]; then
            log_and_notify "Error: Directory ${dir} does not exist." true
            return 1
        fi
    done
    return 0
}

# Execute the backup
execute_backup() {
    sudo rsync -a --progress --backup-dir="${OLD_BACKUP_DIR}/${DATE}" --delete -b -s --include-from "${SCRIPTS}/backupinclude.txt" --exclude-from "${SCRIPTS}/backupexclude.txt" "${SOURCE}" "${BACKUP}" 2>> "${BACKUP_LOG}" || {
        local exit_status=$?
        log_and_notify "rsync failed with exit code ${exit_status}. Check the log file for details." true
        return 1
    }
    return 0
}

# Delete old backup directories
delete_old_backups() {
    log_and_notify "Removing old backups" false
    find $OLD_BACKUP_DIR/* -type d -ctime +$RETENTION_CYCLE -exec sudo rm -rf {} \;
    if [[ $? -eq 0 ]]; then
        log_and_notify "Old backups removed" false
    else
        log_and_notify "Failed to remove old backups" true
    fi
}

# Deal with errors and notifications; keep only log files with errors
handle_backup_logs() {
    if [[ -s "${BACKUP_LOG}" ]]; then
        "${EDITOR_CMD}" "${BACKUP_LOG}"
        log_and_notify "Errors occurred during backup. Check the log file." true
    else
        if [[ -f "${BACKUP_LOG}" ]]; then
            log_and_notify "No errors occurred during backup" false
            if [[ $? -eq 0 && -f "${BACKUP_LOG}" ]]; then
                rm "${BACKUP_LOG}"
            fi
        fi
        log_and_notify "Backup finished" false
    fi
}

# Main
if [[ -f "${CONFIG_FILE}" && -r "${CONFIG_FILE}" ]]; then
    source "${CONFIG_FILE}"
else
    printf "Configuration file not found or not readable at %s\n" "${CONFIG_FILE}"
    exit 1
fi

# check_commands
if ! check_directories; then
    exit 1
fi

# delay notification to allow for cron to start
sleep 2

# execute backup
log_and_notify "Backup is starting" false
if ! execute_backup; then
    exit 1
fi
handle_backup_logs
delete_old_backups
