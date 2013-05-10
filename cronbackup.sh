#!/bin/ksh
. backup.conf
directory=$(pwd)
selsite="$(pwd|cut -f 3 -d"/")"
#backup files
echo "########################################" > $directory/report.log
echo "Report of $selsite" >> $directory/report.log
echo "########################################" >> $directory/report.log
echo "Files sync:" >> $directory/report.log
rsync --stats -LhaEz -e "ssh -p $dport -i $directory/.ssh/id_rsa" $remuser@$rhost:$files_dir $directory/files/ | tee -a $directory/report.log 2>>$directory/error.log
#backup DB
echo "----------------------------------------" >> $directory/report.log
echo "DB sync:" >> $directory/report.log
rsync --stats -haEz -e "ssh -p $dport -i $directory/.ssh/id_rsa" $remuser@$rhost:$db_dir $directory/db/ | tee -a $directory/report.log 2>>$directory/error.log
echo "----------------------------------------" >> $directory/report.log
#Push dbbackup.sh update
if [ "$(cat /var/dbbackup.sh |grep dbbackupversion|cut -f2 -d"=")" -gt "$(cat $directory/db/dbbackup.sh |grep dbbackupversion|cut -f2 -d"=")" ]; then
	echo "old dbbackup.sh version detected, updating"
	scp -P $dport /var/dbbackup.sh $remuser@$rhost:$db_dir/dbbackup.sh
else echo
	echo "dbbackup.sh is up to date or protected";
fi
#clean files every month's first
if [ $(date +%d) = "10" ]; then
	for sitecode in $(ls files/)
	do
		if [ ! -d $directory/archive/files/$sitecode ]; then
			mkdir -p $directory/archive/files/$sitecode $directory/archive/db/temp
		fi
		echo "Patience, creating $selsite : $sitecode archive"
		gtar -czf archive/files/$sitecode/$sitecode-$(date +%F).tar.gz files/$sitecode #make a monthly archive of the site's files
	done

	for datab in $(ls $directory/db/DBBackup/)
	do
		cp $directory/db/DBBackup/$datab/$(ls -t $directory/db/DBBackup/$datab/ | head -n 1) $directory/archive/db/temp/
	done
	gtar -czf archive/db/$selsite-$(date +%F.tar.gz) archive/db/temp/
	rm $directory/archive/db/temp/*
	
	if [ "$(ls $directory/archive/db/ | wc -l)" -gt "15" ]; then
		echo "cleaning db"
		cd $directory/archive/db/ && ls -t | sed '1,15d' | xargs rm && cd $directory
	fi

	for sites in $(ls $directory/archive/files/)
	do
		if [ "$(ls $directory/archive/files/$sites/ | wc -l)" -gt "15" ]; then
		echo "cleaning db"
		cd $directory/archive/files/$sites/ && ls -t | sed '1,15d' | xargs rm && cd $directory
		fi
	done
	echo "synching with --delete"
	rsync --delete -qLhaEz -e "ssh -p $dport -i $directory/.ssh/id_rsa" $remuser@$rhost:$files_dir $directory/files/ | tee -a $directory/report.log 2>>$directory/error.log
	rsync --delete -qhaEz -e "ssh -p $dport -i $directory/.ssh/id_rsa" $remuser@$rhost:$db_dir $directory/db/ | tee -a $directory/report.log 2>>$directory/error.log
fi