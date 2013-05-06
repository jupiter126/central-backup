#!/bin/ksh
# Put this file in /root, chown +x, chattr +i
# Parses the /home/$user directories  to find backup.sh if found, it runs it as the user

for server in $(ls /home)
do
        if [ -f /home/$server/backup.sh ]; then
                if [ -f /home/$server/backup.conf ]; then
                        echo "Patience: running /home/$server/backup.sh as $server"
                        sudo -Hiu $server /home/$server/backup.sh
#                       cat /home/$server/backup.log >> tempmail.txt
                else
                        echo "/home/$server/backup.sh found, but /home/$server/backup.conf is missing skipping"
                fi
        else
                echo "/home/$server/backup.sh not found, skipping"
        fi
done

echo "will email in a future version"
