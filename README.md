This is my Manjaro linux home dir backup script that I started writing in March 2020.

**Description of the Backup Script:**

This bash script automates backups of a directory to another location, with rotation of older backups. It's designed to be robust, including error handling and notifications. The script utilizes `rsync` for the actual backup process and manages retention by deleting old backups.

**Key Functionalities:**

* **Configuration Loading:** Loads configuration values from an external file (`backup.conf`).
* **Duplicate Backup Prevention:** Checks if another rsync process is already running and exits if so. It also uses a timestamp file to prevent the backup from running multiple times per day.
* **Directory Validation:** Verifies the existence of source, backup, and old backup directories.
* **Command Check:**  Confirms that required commands (`rsync`, `find`, `notify-send`, editor) are installed.
* **Logging & Notifications:** Logs messages to a file and optionally sends desktop notifications using `notify-send`.
* **Backup Execution:** Performs the actual backup operation using `rsync` with specified options (archive mode, progress display, backup directory for deleted files, include/exclude lists).
* **Old Backup Deletion:** Removes backups older than a defined retention period.
* **Error Handling & Logging:** Handles errors during the backup process and logs them to a file.  Provides an option to open the log file with a configured editor after the backup completes.

---

```markdown
# Automated Backup Script

This script provides automated backups of specified directories, including rotation of older backups based on retention policies. It's designed for reliability and ease of configuration.

## Prerequisites

* **Bash:**  The script is written in Bash and requires a compatible shell environment (e.g., Linux/macOS).
* **rsync:** The core backup utility. Install using your system’s package manager (e.g., `sudo apt install rsync` on Debian/Ubuntu, `brew install rsync` on macOS).
* **find:** Used for deleting old backups.  Generally pre-installed on most Linux systems.
* **notify-send:** Optional utility for desktop notifications. Install using your system’s package manager (e.g., `sudo apt install notify-send`).
* **Text Editor:** A text editor configured in the script (`EDITOR_CMD`) to view log files.

## Configuration

The script relies on a configuration file (`backup.conf`, typically located at `/home/rob/Files/Scripts/backup.conf` - adjust this path if needed).  This file should contain the following variables:

```
SOURCE="/path/to/source/directory"  # The directory to be backed up
BACKUP="/path/to/backup/directory" # The primary backup destination
OLD_BACKUP_DIR="/path/to/old/backups/directory" # Where rotated backups are stored
RETENTION_CYCLE=30 # Number of days to keep old backups (e.g., 30 for one month)
BACKUP_LOG="/path/to/backup.log"  # Log file location
EDITOR_CMD="nano" # Command to open the log file (e.g., nano, vim, gedit)
SCRIPTS="/path/to/scripts/directory" # Directory containing backupinclude.txt and backupexclude.txt
BACKUP_VERSION="1.0"  # Backup version number for logging purposes
RUN_FILE="/tmp/.backup_ran_today" # File used to track if the script has run today
```

**Important:** Ensure that all paths are absolute and correct. Incorrect paths will lead to errors.

## Usage

1. **Configure `backup.conf`:**  Edit the configuration file with your desired settings.
2. **Create Include/Exclude Files (Optional):** Create files named `backupinclude.txt` and `backupexclude.txt` within the `SCRIPTS` directory to specify which files or directories should be included or excluded from the backup, respectively.  Each line in these files represents a pattern to match.
3. **Make the Script Executable:** `chmod +x /path/to/your/backup_script.sh` (replace `/path/to/your/backup_script.sh` with the actual path).
4. **Run the Script:** `./backup_script.sh [sleep_time]`  (Optional: specify a sleep time in seconds to allow desktop environment to load)

## Script Logic & Key Functions

* `check_run_file()`: Prevents multiple backups on the same day by checking for a timestamp file.
* `check_directories()`: Validates that all required directories exist.
* `check_commands()`: Ensures necessary commands are installed.
* `log_and_notify()`: Logs messages to a file and optionally sends desktop notifications.
* `execute_backup()`: Performs the rsync backup operation, creating a new directory for each backup cycle.  It also handles potential errors during the rsync process.
* `delete_old_backups()`: Removes backups older than the specified retention period using `find`.
* `handle_backup_logs()`: Checks for error logs and opens them in the configured editor if necessary.

## Potential Improvements & Considerations

* **Error Handling:** While basic error handling is present, more sophisticated error reporting and recovery mechanisms could be added.  Consider sending email notifications on failure.
* **Configuration Validation:** Add validation to `config_load()` to ensure that configuration variables are set correctly (e.g., checking if paths exist).
* **Logging Level:** Implement different logging levels (e.g., DEBUG, INFO, WARNING, ERROR) for more granular control over log output.
* **Testing:**  Thoroughly test the script with various scenarios and configurations to ensure its reliability.
* **Security:** If backing up sensitive data, consider encrypting the backup destination.
* **Scheduling:** Use a scheduler like `cron` or `systemd timers` to automate the execution of the script at regular intervals.

## License

Copyright (c) [2020] [Rob Wijhenke, Putte, The Netherlands]

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

**Key improvements in this version:**

*   **Clearer Explanations:** More detailed explanations of each function and its purpose.
*   **Configuration Instructions:**  More explicit instructions on configuring the `backup.conf` file, including example values.
*   **License Placeholder added**
