#!/bin/bash
#
# Backup script for Linux systems (tested on Manjaro and Arch).
#
# This script creates backups of a specified source directory to a backup 
# directory, manages old backups based on a retention policy, and logs 
# errors and notifications.
#
# For daily execution, create a symlink to the script in cron.daily:
# sudo ln -s /home/rob/Files/Scripts/backup.sh /etc/cron.daily/backup
#
# Author: Rob Wijhenke
# Initial Release: March 6 2020
# Current Version: v2.0 rev-a February 12 2025
#
# Version History:
# v1.0   March 6 2020              Initial build
# v1.1   March 19 2023             Fixed bug, cleaned up code
# v1.2   December 21 2023          Refactored, introduced functions
# v1.2   rev-a December 24 2023    Added error handling
# v1.2   rev-b January 3 2024      Improved error & notification handling
# v1.3   January 6 2024            Full refactoring, added configuration file 
#                                  and re-wrote error handling and program flow
# v1.3   rev-c January 11 2024     Fixed bug in error handling
# v1.3   rev-d January 12 2024     Improved RETENTION_CYCLE, added user manual
#        rev-e+f January 25 2024   Improved error handling
#        rev-g February 3 2024     Added daily run file check to be cron independent
#        rev-h May 7 2024          Moved more parameters to config file
# v2.0   February 5 2025           Partial re-write to improve robustness
#        rev-a February 12 2025    Fixed some bugs
# ~ end comments ~


# Exit immediately if a command exits with a non-zero status.
set -e
# Treat unset variables as an error.
set -u

# --- Functions ---

# Check if script (or another sync) is alreay running. If so exit the backup
if pgrep -x "rsync" > /dev/null; then
    log_and_notify "rsync process already running. Skipping backup." false
    exit 0
fi

# Check if the script has already run today. Uses a timestamp file.
check_run_file() {
    # Check if the run file exists and was last modified today
    if [[ -f "${RUN_FILE}" ]] && [[ "$(date -r "${RUN_FILE}" +%F)" == "$(date +%F)" ]]; then
        # The run file exists and was last modified today, so exit the script
        log_and_notify "Backup already ran today"
        exit 0
    fi

    # The run file doesn't exist or wasn't last modified today, so touch the run file and continue with the script
    touch "${RUN_FILE}"
}

# Check if required directories exist.
check_directories() {
    for dir in "${SOURCE}" "${BACKUP}" "${OLD_BACKUP_DIR}"; do
        if [[ ! -d "${dir}" ]]; then
            log_and_notify "Error: Directory ${dir} does not exist." true
            return 1 # Indicate failure
        fi
    done
}

# Check if required commands are installed.
check_commands() {
    for command_to_check in rsync find notify-send "${EDITOR_CMD}"; do
        if ! command -v "$command_to_check" &> /dev/null; then
            log_and_notify "Error: $command_to_check is not installed." true || exit 1
        fi
    done
}

# Log messages to a file and optionally send a desktop notification.
log_and_notify() {
    local message="$1"
    local isError="${2:-false}"
    local logFile="${3:-$BACKUP_LOG}" # Simplified default assignment

    # Send a desktop notification
    if command -v notify-send >/dev/null 2>&1; then
        notify-send "${message}"
    else
        echo "${message}" # Fallback to printing to console
    fi

    # If it's an error message AND not an empty message, log it
    if [[ "${isError}" = true ]] && [[ -n "${message}" ]]; then
        # Ensure the log file exists - ONLY if there's an error
        if [[ ! -f "${logFile}" ]]; then
            touch "${logFile}"
        fi
        # Append the message to the log file
        printf "%s\n" "${message}" >> "${logFile}"
    fi
}

# Start backups
execute_backup() {
    local rsync_result
    local backup_dir="${OLD_BACKUP_DIR}${DATE}"

    # Create the backup directory *before* running rsync.
    if ! sudo mkdir -p "$backup_dir"; then
        log_and_notify "Failed to create backup directory: $backup_dir" true
        return 1
    fi

    # Run rsync and WAIT for it to finish.
    sudo rsync -a --progress --backup-dir="$backup_dir" --delete -b -s --include-from "${SCRIPTS}/backupinclude.txt" --exclude-from "${SCRIPTS}/backupexclude.txt" "${SOURCE}" "${BACKUP}" 2>> "${BACKUP_LOG}"
    rsync_result=$?

    # Check the result of rsync.
    if ! [[ $rsync_result -eq 0 ]]; then
        log_and_notify "rsync failed with exit code ${rsync_result}. Check the log file for details." true
        # Clean up the (likely empty) backup directory if rsync fails.
        sudo rmdir "$backup_dir" 2>/dev/null  # Suppress error if directory isn't empty
        return 1
    fi

    # Only now, after rsync has COMPLETELY finished, can you safely return.
}

# Remove backups beyond retention period
delete_old_backups() {
    log_and_notify "Removing old backups" false

    # Use mtime (modification time) instead of ctime for backup rotation.
    find "$OLD_BACKUP_DIR" -mindepth 1 -type d -mtime +"$RETENTION_CYCLE" -exec sh -c 'sudo rm -rf "$1"; test $? -eq 0' sh {} \;
    find_result=$?

    if [[ $find_result -eq 0 ]]; then
        log_and_notify "Old backups removed" false
    else
        log_and_notify "Failed to remove old backups (or some files could not be removed)" true
    fi
}

# Deal with errors and notifications; keep only log files with errors
handle_backup_logs() {
    if [[ -f "${BACKUP_LOG}" ]]; then
        if [[ -s "${BACKUP_LOG}" ]]; then
            "${EDITOR_CMD}" "${BACKUP_LOG}"
            log_and_notify "Errors occurred during backup. Check the log file." true
        else
            rm "${BACKUP_LOG}"
            log_and_notify "No errors occurred during backup" false
        fi
    fi
    log_and_notify "Backup finished" false
}

# --- Main Script ---
config_load() {
    local config_file="/home/rob/Files/Scripts/backup.conf"
    if [[ -f "$config_file" && -r "$config_file" ]]; then
        source "/home/rob/Files/Scripts/backup.conf" # use full path to avoid shellcheck warning
        source_result=$?
        if [[ $source_result -ne 0 ]]; then
            printf "Error sourcing configuration file %s\n" "$config_file" >&2
            log_and_notify "Error sourcing configuration file. Check the log for details." true
            return 1
        fi
    else
        printf "Configuration file not found or not readable at %s\n" "$config_file" >&2
        log_and_notify "Configuration file not found or not readable." true
        return 1
    fi
    return 0
}

if ! config_load; then
    exit 1
fi


# Check if backup already run today. if so, exit
check_run_file

# Wait for 10 seconds for the desktop to load as this script runs on first startup
# if not adding a parameter or add a parameter to set it yourself
sleep "${1:-1}"

# check_commands
check_directories || exit 1

# execute backup
log_and_notify "Backup is starting. Version is ${BACKUP_VERSION}" false
execute_backup || exit 1
handle_backup_logs
delete_old_backups
