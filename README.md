# backup
This is my linux home directory backup script that I started writing in March 2020.

It uses rsync to copy all files mentioned in backupinclude.txt,
excluding everything in backupexclude.txt, to a designated location.
It uses a retention cycle parameter effectively deleting all backups that
fall outside the parameters value. So RETENTION_CYCLE=14 means it will
delete all folders/files older than 14 days. All activites are logged.

There's a lot of documentation in the script already so I think this is all
quite self-explanatory but reach out if you have questions.

In 2023 I started re-writing the script resulting is improved error-handling,
error logging, user notifications. It now also justifies it's own user manual,
see backup.manual for that.
