#!/bin/ksh
# Put this file in /root, chown +x, chattr +i
# Parses the /home/$user directories  to find backup.sh if found, it runs it as the user
echo "Sync started on $(uname -n), the $(date +%Y%m%d) at $(date +%R)" > /root/report.log

for server in $(ls /home)
do
        if [ -f /home/$server/backup.sh ]; then
                if [ -f /home/$server/backup.conf ]; then
                        echo "Patience: running /home/$server/backup.sh as $server"
                        sudo -Hiu $server /home/$server/backup.sh
                else
                        echo "/home/$server/backup.sh found, but /home/$server/backup.conf is missing skipping"
                fi
        else
                echo "/home/$server/backup.sh not found, skipping"
        fi
done

#generate report - customise at your needs
echo "-------------------------------------------------------------------" >> /root/report.log
echo "Sync report" >> /root/report.log
echo "-------------------------------------------------------------------" >> /root/report.log
for server in $(ls /home)
do
        if [ -f /home/$server/backup.sh ] && [ -f /home/$server/backup.conf ] && [ "$(cat /home/$server/report.log)" != "" ] ; then
			cat /home/$server/report.log >> /root/report.log
			rm /home/$server/report.log
        fi
done
echo "-------------------------------------------------------------------" >> /root/report.log
echo "DB report" >> /root/report.log
echo "-------------------------------------------------------------------" >> /root/report.log
for server in $(ls /home)
do
        if [ -f /home/$server/backup.sh ] && [ -f /home/$server/backup.conf ] && [ "$(cat /home/$server/db/db-report.log)" != "" ] ; then
		cat /home/$server/db/db-report.log >> /root/report.log
		rm /home/$server/db/db-report.log
        fi
done
echo "-------------------------------------------------------------------" >> /root/report.log
echo "Drives log" >> /root/report.log
echo "-------------------------------------------------------------------" >> /root/report.log
df -h >> /root/report.log
echo "-------------------------------------------------------------------" >> /root/report.log
cd /home/
du -hs >> /root/report.log
cd /root/
echo "-------------------------------------------------------------------" >> /root/report.log
dmesg | tail -n 20 >> /root/report.log
echo "-------------------------------------------------------------------" >> /root/report.log
echo "Sync and report finished on $(uname -n), the $(date +%Y%m%d) at $(date +%R)" >>/root/report.log
echo "-------------------------------------------------------------------" >> /root/report.log

cat /root/report.log | mail -s "Backup Report $(date)" jupiter126@gmail.com
