#!/bin/ksh
. backup.conf
directory=$(pwd)
echo "directory=$directory"

#backup files
echo "$directory files" >> $directory/report.log
rsync --stats -haEz -e "ssh -i $directory/.ssh/id_rsa" $remuser@$rhost:$files_dir $directory/files/ | grep "Total bytes received:" | tee -a $directory/report.log 2>>$directory/error.log
#backup DB
echo "$directory DB" >> $directory/report.log
rsync --stats -aEz -e "ssh -i $directory/.ssh/id_rsa" $remuser@$rhost:$db_dir $directory/db/ | grep "Total bytes received:" | tee -a $directory/report.log 2>>$directory/error.log

#clean files every month's first
if [ $(date +%d) = "01" ]; then
	#make a monthly archive of the site's files
	#copy db in monthly db backup
	#clean archives
        #rsync -aEz --delete -e "ssh -i $directory/.ssh/id_rsa" root@rhost:/home/.sites/ $directory/files/
        #rsync -aEz --delete -e "ssh -i $directory/.ssh/id_rsa" root@rhost:/home/users/jupiter/ $directory/db/
        echo "not done yet"
fi