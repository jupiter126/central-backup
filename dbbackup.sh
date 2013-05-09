#!/bin/bash
dbbackupversion=2
# This is a simple mysql local backup script
# It dumps databases in gzip, then adds ad password with rar and mail them once a day
# It depends on rar and mutt (with a functionnal mail system)
# Please set the variables according to your needs
# You are the sole responsible for running this script and all the consequences it could have.

directory="$( cd -P "$( dirname "${BASH_SOURCE[0]}" )" && pwd )" && cd $directory
source $directory/dbbackup.conf
daate=$(date +%Y%m%d-%T)
echo "DB on $(date)" > $directory/db-report.log
if [ "$sendemail" = "Yes" ] && [ ! -d $directory/tmpmail ]; then
	mkdir -p $directory/tmpmail
fi
#We do a DB list
databases=`/usr/bin/mysql --user=$usersql --password=$mdpsql -e "SHOW DATABASES;" | grep -Ev "(Database|information_schema)"` 2>$directory/dumperror.log
#################################################
# for each DB, we do a dump, then clean backups
for db in $databases; do
	echo $db
	if [ ! -d $directory/DBBackup/$db ]; then
		mkdir -p $directory/DBBackup/$db
	fi
	/usr/bin/mysqldump -u $usersql -p$mdpsql $db | gzip > "$directory/DBBackup/$db/$db-$daate.sql.gz" 2>>$directory/dumperror.log && echo "$db - ok" >> $directory/db-report.log
	if [ "$(ls $directory/DBBackup/$db/ | wc -l)" -gt "15" ]; then
		echo cleaning
		cd $directory/DBBackup/$db/ && ls && ls -t | sed '1,15d' | xargs rm && cd $directory #Pour chaque db, on garde deux semaines d'historique
	fi
	if [ "$sendemail" = "Yes" ]; then
		cp $directory/DBBackup/$db/$db-$daate.sql.gz $directory/tmpmail/
	fi
done
echo "------------------------------------------" >> $directory/db-report.log
echo "Utilisation generale des disques:" >> $directory/db-report.log
echo "$(df -h|grep -v "/dev/")" >> $directory/db-report.log
echo "------------------------------------------" >> $directory/db-report.log
echo " " >> $directory/db-report.log
echo "Espace occupe par le backup sur le serveur" >> $directory/db-report.log
echo "$(du -h --max-depth=1 DBBackup/)" >> $directory/db-report.log
echo " " >> $directory/db-report.log
cp $directory/db-report.log $directory/tmpmail/

#mail - should work
if [ "$sendemail" = "Yes" ]; then
	if [ "$(cat $directory/dumperror.log)" = "" ]; then
		topic="Resume quotidien: OK $(date +%F)"
	else
		topic="Resume quotidien: ERREUR dans le dump des DB $(date +%F)"
		cat $directory/db-report.log >> $directory/dumperror.log && mv $directory/dumperror.log $directory/db-report.log
	fi
	echo "Data compression and mail sending... PATIENCE... "
	rar a $directory/complete-$daate-db.rar -rv4 -m5 -Hp$mdprar -v9500k $directory/tmpmail/*
	echo "compression done"
	for k in $(ls $directory |grep complete-$daate-db)
	do
		echo "sending $k by mail"
		if [ "$(echo $k|grep -v "part2")|grep -v "part3"|grep -v "part4"|grep -v "part5"|grep -v "part6"|grep -v "part7"|grep -v "part8"|grep -v "part9"|grep -v "part10"|grep -v "part11"|grep -v "part12"|grep -v "part13"|grep -v "part14"|grep -v "part15"|grep -v "part16"|grep -v "part17"|grep -v "part18"|grep -v "part19"|grep -v "part20"" != "" ]; then 
			sed -i "1i Compte rendu du backup de $(uname -n) le $daate" $directory/db-report.log
			sed -i "2i \"#####################################################################\"" $directory/db-report.log
			mutt -s "$topic" -a $k -- $recipients < $directory/db-report.log && echo "Mail sent, sleeping 3 seconds, patience" && sleep 3
		else
			echo "sending mail"
			mutt -s "$topic" -a $k -- $recipients < $directory/db-report.log && echo "Mail sent"
		  fi
		  rm $k
	done
	rm $directory/tmpmail/*
else
	echo "Script ran, no mail was sent"
fi