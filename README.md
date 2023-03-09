# backup
This is my linux home directory backup script.

This script uses rsync to copy all files mentioned in backupinclude.txt,
excluding everything in backupexclude.txt, to a designated location.
It uses a retention cycle parameter effectively deleting all backups that
fall outside the parameters value. So RETENTION_CYCLE=14 means it will
delete all folders/files older than 14 days. All activites are logged.

I think this is all quite self-explanatory, reach out if you have questions.
