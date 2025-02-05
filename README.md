This is my Manjaro linux home dir backup script that I started writing in March 2020.

It uses rsync to copy all files mentioned in backupinclude.txt, excluding everything 
in backupexclude.txt, to a designated location. It uses a retention cycle parameter 
effectively deleting all backups that fall outside the parameter's value. Starting
with 0 , RETENTION_CYCLE=14 means keeping all folders/files of the last 15 days. 
All errors are logged and displayed to the user with notify-send. Change that into
whatever you like or install it on your distro.

There's a lot of documentation in the script already so I think this is all quite 
self-explanatory but reach out if you have questions.

Since I started developing this I made many changes, refactored and rewrote the
script resulting in improved error-handling, error logging and user notifications. 
