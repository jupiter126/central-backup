Summary:

This script allows to quickly and securely set-up backups from linux servers/databases to an OpenBSD backup server.
The linux server dumps it's databases in a particular folder, The OpenBSD server uses a different user/ssh-key for each server, it rsyncs files and database folders.

files:
/root/cronbackup_launcher.sh - OpenBSD - place in cron daily - Parses the /home/ directories to find backup.sh. If found, it is ran as the user.
/home/$server/backup.conf - OpenBSD - Configuration for that server (1 user/server to backup*)
/home/$server/backup.sh - OpenBSD - symbolic link to /usr/local/bin/cronbackup.sh
/usr/local/cronbackup.sh - OpenBSD - the core sync script - Loads settings from the users backup.conf, rsyncs files and db, archive and clean monthly
/home/$backupuser/dbbackup.sh - Linux Webserver - The script that backs up the databases

Installation:
put /root/cronbackup_launcher.sh on the OpenBSD - add it to cron daily
create a backup user on each linux box and put /home/$backupuser/dbbackup.sh in his home - add it on cron daily

*) For each server to backup: create a user with a home dir on the OpenBSD
then, become the user, generate an ssh key, and create the config:

#su - username
$ssh-keygen -t rsa -b 16384 -C "$(whoami)@$(hostname)-$(date +%Y%m%d)" #or use ecdsa if both ends support it - don't forget to add the id_rsa.pub to the ~/.ssh/authorized_keys of the webserver!
$ln -s backup.sh /usr/local/bin/cronbackup.sh
$nano backup.conf # and put the following 3 lines:
#######################################
files_dir=/var/www #where the files are on the server
db_dir="/home/myuser/DBBackup" #where the db dumps are on the server
rhost=10.0.0.1 #IP/hostname of the server
remuser=mydbbackupuser #name of user to login on server
#######################################

Linux server
On the server we want to backup, create a user to make the database backups and add dbbackup.sh to his home directory
Open this file and set your sql user and password.
If mutt and rar are installed and configured, you can choose sendemail="Yes", set recipients and a rar password (I use rar as an easy way to split and password protect the archives)

Improvements are to be done yet (email reports, and push update features for example) to make this script more user friendly, however I won't include any advanced options (like exclude), to keep it user friedly!