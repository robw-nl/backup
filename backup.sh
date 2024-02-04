#!/bin/bash
#
# this script is developed for manjaro and arch. For other distros change rsync and
# other commands to accomodate your distro. For daily execution make an autostart
# entry. The script checks if it already ran that day. Alternatively use cron.
#
# created by rob wijhenke november 2020
# v1.0   March 6 2020            initial realease
# v1.1   rev-a March 9 2023      fixed bug
# v1.1   rev-b March 19 2023     cleaned up code
# v1.2   December 21 2023        refactored introducing functions
# v1.2   rev-a December 24 2023  added error handling
# v1.2   rev-b January 3 2024    added delete empty logs function
# v1.2   rev-b January 3 2024    improved error & notification handling
# v1.3         January 6 2024    full refactoring, the code became too complex.
#                                added configuration file and re-wrote error 
#                                handling en program flow
# v1.3   rev-c January 11 2024   fixed bug in error handling
# v1.3   rev-d January 12 2024   re-added old backup deletion following retension
#                                cycle, added a user manual
#        rev-e January 25 2024   improved error handling
#        rev-f January 28 2024   improved error handling
#        rev-g February 3 2024   added daily run file check to be cron independent
#                                and fixed some minor issues. Added a delay parameter
#                                to delay execution with n secondse.g. ../backup.sh 10

set -e
set -u

backup_version="rev-g February 3 2024"

# Check if the run file exists and was last modified today
check_run_file() {
    # Check if the run file exists and was last modified today
    if [[ -f "${RUN_FILE}" ]] && [[ "$(date -r "${RUN_FILE}" +%Y%m%d)" == "$(date +%Y%m%d)" ]]; then
        # The run file exists and was last modified today, so exit the script
        echo "Backup  already run today"
        log_and_notify "Backup  already run today"
        exit 0
    fi

    # The run file doesn't exist or wasn't last modified today, so touch the run file and continue with the script
    touch "${RUN_FILE}"
}

# Check if directories exist
check_directories() {
    for dir in "${SOURCE}" "${BACKUP}" "${OLD_BACKUP_DIR}"; do
        if [[ ! -d "${dir}" ]]; then
            log_and_notify "Error: Directory ${dir} does not exist." true
            return 1
        fi
    done
}

# Check if required commands are installed
check_commands() {
    for cmd in rsync find notify-send "${EDITOR_CMD}"; do
        if ! command -v "${cmd}" > /dev/null 2>&1; then
            log_and_notify "Error: ${cmd} is not installed." true || exit 1
        fi
    done
}

# Configuration - change location appropriately
CONFIG_FILE="/home/rob/Files/Scripts/backup.conf"

# Log errors log file and on screen; progress only on screen
log_and_notify() {
    local message="$1"
    local isError="${2:-false}"
    local logFile="${3:-${BACKUP_LOG}}"

    # Send a desktop notification
    if command -v notify-send >/dev/null 2>&1; then
        notify-send "${message}"
    else
        echo "${message}"
    fi

    # If it's an error message AND not an empty message, log it
    if [[ "${isError}" = true ]] && [[ -n "${message}" ]]; then
        # Ensure the log file exists
        if [[ ! -f "${logFile}" ]]; then
            touch "${logFile}"
        fi
        # Append the message to the log file
        printf "%s\n" "${message}" >> "${logFile}"
    fi
}

# Execute the backup
execute_backup() {
    sudo rsync -a --progress --backup-dir="${OLD_BACKUP_DIR}/${DATE}" --delete -b -s --include-from "${SCRIPTS}/backupinclude.txt" --exclude-from "${SCRIPTS}/backupexclude.txt" "${SOURCE}" "${BACKUP}" 2>> "${BACKUP_LOG}"
    if [[ $? -ne 0 ]]; then
        log_and_notify "rsync failed with exit code $?. Check the log file for details." true
        return 1
    fi
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
    elif [[ -f "${BACKUP_LOG}" ]]; then
        rm "${BACKUP_LOG}"
        log_and_notify "No errors occurred during backup" false
    fi
    log_and_notify "Backup finished" false
}

# Main
if [[ -f "${CONFIG_FILE}" && -r "${CONFIG_FILE}" ]]; then
    source "${CONFIG_FILE}"
else
    printf "Configuration file not found or not readable at %s\n" "${CONFIG_FILE}"
    exit 1
fi

# Check if backup already run today. if so, exit
check_run_file

# check_commands
check_directories || exit 1

# Wait for 10 seconds for the desktop to load as this script runs on first startup
# or at once if not adding a parameter
sleep 10

# execute backup
log_and_notify "Backup is starting. Version is ${backup_version}" false
execute_backup || exit 1
handle_backup_logs
delete_old_backups
