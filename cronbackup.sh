#!/bin/ksh
. backup.conf
directory=$(pwd)

#backup files
echo "########################################" > $directory/report.log
echo "Report of $(pwd|cut -f 3 -d"/")" >> $directory/report.log
echo "########################################" >> $directory/report.log
echo "Files sync:" >> $directory/report.log
#rsync --stats -haEz -e "ssh -p $dport -i $directory/.ssh/id_rsa" $remuser@$rhost:$files_dir $directory/files/ | grep "Total bytes received:" | tee -a $directory/report.log 2>>$directory/error.log
rsync --stats -haEz -e "ssh -p $dport -i $directory/.ssh/id_rsa" $remuser@$rhost:$files_dir $directory/files/ | tee -a $directory/report.log 2>>$directory/error.log
#backup DB
echo "----------------------------------------" >> $directory/report.log
echo "DB sync:" >> $directory/report.log
#rsync --stats -haEz -e "ssh -p $dport -i $directory/.ssh/id_rsa" $remuser@$rhost:$db_dir $directory/db/ | grep "Total bytes received:" | tee -a $directory/report.log 2>>$directory/error.log
rsync --stats -haEz -e "ssh -p $dport -i $directory/.ssh/id_rsa" $remuser@$rhost:$db_dir $directory/db/ | tee -a $directory/report.log 2>>$directory/error.log
echo "----------------------------------------" >> $directory/report.log
#clean files every month's first
if [ $(date +%d) = "01" ]; then
        #make a monthly archive of the site's files
        #copy db in monthly db backup
        #clean archives
        #rsync -aEz --delete -e "ssh -i $directory/.ssh/id_rsa" root@rhost:/home/.sites/ $directory/files/
        #rsync -aEz --delete -e "ssh -i $directory/.ssh/id_rsa" root@rhost:/home/users/jupiter/ $directory/db/
        echo "not done yet"
fi
