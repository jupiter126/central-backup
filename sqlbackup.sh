#!/bin/bash

# This is a simple mysql local backup script
# It dumps databases in gzip, then adds ad password with rar and mail them once a day
# It depends on rar and mutt (with a functionnal mail system)
# Please set the variables according to your needs

#################################################
#           D I S C L A I M E R                 #
#################################################
# You are the sole responsible for running this script and all the consequences it could have.

#################################################
#            V A R I A B L E S                  #
#################################################

# Mettre le mot de passe root de MySQL
mdpsql="7Vy9e_536B"
sendemail="No"
# Destinataire du mail (recquiert mutt sur le serveur)
#destinataires="nelson@openskill.lu backup@transitic.com"
# Time the mails are sent
#Heure_du_Mail="12" # !!! a accorder en fonction de cron !!! --> actuellement "00 */12 * * * ", donc un multiple de 6
# rar est utilise afin de mettre un mot de passe sur l'archive
mdprar=RE_03Svv8TuMG77K866qY4wgm4vVJF6.oqxSBGhH5TMXCvrtYPDK9VFGfp2e-RJ

#################################################
#      F I N   D E S    V A R I A B L E S       #
#################################################
directory="$( cd -P "$( dirname "${BASH_SOURCE[0]}" )" && pwd )" && cd $directory
daate=$(date +%Y%m%d-%T)
#On fait une liste des db
#databases=`/usr/bin/mysql --user=root --password=$mdpsql -e "SHOW DATABASES;" | grep -Ev "(Database|information_schema|mysql)"`
databases=`/usr/bin/mysql --user=root --password=$mdpsql -e "SHOW DATABASES;" | grep -Ev "(Database|information_schema)"`
#################################################
# pour chaque db, on fait un dump et on nettoye les backups
for db in $databases; do
        echo $db
        if [ ! -d $directory/DBBackup/$db ]; then
                mkdir -p $directory/DBBackup/$db
        fi
        /usr/bin/mysqldump -u root -p$mdpsql $db | gzip > "$directory/DBBackup/$db/$db-$daate.sql.gz"
        if [ "$(ls $directory/DBBackup/$db/ | wc -l)" -gt "15" ]; then
                echo cleaning
                cd $directory/DBBackup/$db/ && ls && ls -t | sed '1,15d' | xargs rm && cd $directory #Pour chaque db, on garde deux semaines d'historique
        fi
        if [ "$sendemail" = "Yes" ]; then
                cp $directory/DBBackup/$db/$db-$daate.sql.gz $directory/DBBackup/tmpmail/
        fi
done

#################################################

#mail - not done yet.
#if [ "$sendmail" = "Yes" ]; then
#        if [ "$(cat dumperrors.txt)" != "" ]; then
#                sed -i "1i !!!Erreurs de dump!!!" mailmessage.txt
#                cat dumperrors.txt >> mailmessage.txt
#                echo "#####################################################################">>mailmessage.txt
#                rm dumperrors.txt
#        fi
#        echo "Utilisation generale des disques">>mailmessage.txt
#        echo "$(df -h)" >> mailmessage.txt
#        echo "#####################################################################">>mailmessage.txt
#        echo "Espace occupe par le backup sur le serveur">>mailmessage.txt
#        echo " " >> mailmessage.txt
#        echo "$(du -h --max-depth=1)" >> mailmessage.txt
#        echo "#####################################################################">>mailmessage.txt
#        echo "Fin du rapport a $(date +%Y%m%d-%T)">>mailmessage.txt
#        cp mailmessage.txt tmpmail/
#        echo "Compression des fichiers et envoi du mail, patience"
#        rar a complete-$daate-db.rar -rv4 -m5 -Hp$mdprar -v9500k tmpmail/*
#        echo "compression done"
#        for k in $(ls|grep complete-$daate-db)
#        do
#                echo "sending $k by mail" && echo "$k db" > maildb.txt
#                if [ "$(echo $k|grep -v "part2")|grep -v "part3"|grep -v "part4"|grep -v "part5"|grep -v "part6"|grep -v "part7"|grep -v "part8"|grep -v "part9"|grep -v "part10"|grep -v "part11"|grep -v "part12"|grep -v "part13"|grep -v "part14"" != "" ]; then
#                        sed -i "1i \"Compte rendu du backup de $(uname -n) le $daate\"" mailmessage.txt
#                        sed -i "2i #####################################################################" mailmessage.txt
#                        cat mailmessage.txt >> maildb.txt
#                        mutt -s "Resume quotidien et - $k" -a $k -- $destinataires < maildb.txt && echo "Mail sent, sleeping 3 seconds, patience" && sleep 3 && echo " " > mailmessage.txt && echo "cleaned mailmessage.txt"
#                else
#                        mutt -s "db - $k" -a $k -- $destinataires < maildb.txt && echo "Mail sent"
#                fi
#                rm $k
#        done
#        rm tmpmail/*
#else
#        echo "script de sauvegarde execute sur $(uname -n) le $daate" >> mailmessage.txt
#fi