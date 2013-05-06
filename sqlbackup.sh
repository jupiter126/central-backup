#!/bin/bash

# This is a simple mysql local backup script
# It dumps databases in gzip, then adds ad password with rar and mail them once a day
# It depends on rar and mutt (with a functionnal mail system)
# Please set the variables according to your needs
# You are the sole responsible for running this script and all the consequences it could have.

directory="$( cd -P "$( dirname "${BASH_SOURCE[0]}" )" && pwd )" && cd $directory
source $directory/dbbackup.conf
daate=$(date +%Y%m%d-%T)
rm $directory/mailmessage.txt
echo "Report of $directory DB on $(date)" > $directory/db-report.log
if [ "$sendemail" = "Yes" ] && [ ! -d $directory/tmpmail ]; then
        mkdir -p $directory/tmpmail
fi
#We do a DB list
databases=`/usr/bin/mysql --user=$usersql --password=$mdpsql -e "SHOW DATABASES;" | grep -Ev "(Database|information_schema)"` 2>>$directory/dumperror.log
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
echo "### done ###" >> $directory/db-report.log && echo " " >> $directory/db-report.log

#mail - should work

if [ "$(cat $directory/dumperror.log)" != "" ]; then
	sed -i "1i !!! Dump ERRORS!!!" $directory/db-report.log
	cat $directory/dumperror.log >> $directory/db-report.log && echo "1" > $directory/critical
	echo "#####################################################################" >> $directory/mailmessage.txt
	rm $directory/dumperror.log
fi
echo "Utilisation generale des disques" >> $directory/mailmessage.txt
echo "$(df -h)" >> $directory/mailmessage.txt
echo "#####################################################################" >> $directory/mailmessage.txt
echo "Espace occupe par le backup sur le serveur" >> $directory/mailmessage.txt
echo " " >> $directory/mailmessage.txt
echo "$(du -h --max-depth=1)" >> $directory/mailmessage.txt
echo "#####################################################################" >> $directory/mailmessage.txt
echo "Fin du rapport a $(date +%Y%m%d-%T)" >> $directory/mailmessage.txt
cp $directory/db-report.log $directory/mailmessage.txt $directory/tmpmail/ && cat $directory/mailmessage.txt >> $directory/db-report.log
if [ "$sendemail" = "Yes" ]; then
        echo "Data compression and mail sending... PATIENCE... "
        rar a $directory/complete-$daate-db.rar -rv4 -m5 -Hp$mdprar -v9500k $directory/tmpmail/*
        echo "compression done"
        for k in $(ls|grep $directory/complete-$daate-db)
        do
                echo "sending $k by mail" && echo "$k db" > $directory/maildb.txt
		if [ "$(echo $k|grep -v "part2")|grep -v "part3"|grep -v "part4"|grep -v "part5"|grep -v "part6"|grep -v "part7"|grep -v "part8"|grep -v "part9"|grep -v "part10"|grep -v "part11"|grep -v "part12"|grep -v "part13"|grep -v "part14"|grep -v "part15"|grep -v "part16"|grep -v "part17"|grep -v "part18"|grep -v "part19"|grep -v "part20"" != "" ]; then 
                        sed -i "1i \"Compte rendu du backup de $(uname -n) le $daate\"" $directory/mailmessage.txt
                        sed -i "2i \"#####################################################################\"" $directory/mailmessage.txt
                        cat $directory/mailmessage.txt >> $directory/maildb.txt
#                       mutt -s "Resume quotidien et - $k" -a $k -- $recipients < $directory/maildb.txt && echo "Mail sent, sleeping 3 seconds, patience" && sleep 3 
			echo " " > $directory/mailmessage.txt && echo "cleaned mailmessage.txt"
                else
                        echo "sending mail"
#                        mutt -s "db - $k" -a $k -- $recipients < $directory/maildb.txt && echo "Mail sent"
                fi
                rm $k
        done
        rm $directory/tmpmail/*
else
        echo "script de sauvegarde execute sur $(uname -n) le $daate" >> $directory/mailmessage.txt
fi