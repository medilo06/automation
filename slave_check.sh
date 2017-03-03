#!/bin/bash

server_name="10.10.2.156"
SENDER="Network Operation Center <noc@email.com>"
RECEIVER="email@email.com"
SUBJECT="<autoemail> Mysql Replication for $server_name is reporting Error `date +\%Y\%m\%d`";
MAIL_TXT="Subject: $SUBJECT\nFrom: $SENDER\nTo: $RECEIVER\n\n"
USERNAME="root"
PASSWORD="XXXXXX"


# change mysql credentials in the following commands if you running monitor using a user other than root
sql_thread_running=$(/usr/bin/mysql -u $USERNAME -p$PASSWORD -e "show slave status\G" | awk -F":" '/Slave_SQL_Running/ { print $2 }' | tr -d ' ')
io_thread_running=$(/usr/bin/mysql -u $USERNAME -p$PASSWORD -e "show slave status\G" | awk -F":" '/Slave_IO_Running/ { print $2 }' | tr -d ' ')
seconds_late=$(/usr/bin/mysql -u $USERNAME -p$PASSWORD -e "show slave status\G" | awk -F":" '/Seconds_Behind_Master/ { print $2 }' | tr -d ' ')
seconds_late=$(($seconds_late+0))


if [ "$sql_thread_running" = "No" ] || [ "$io_thread_running" = "No" ] || [ $seconds_late -gt 0 ]; then

   log_file="/opt/logs/log_slave_status_`date +\%Y\%m\%d-\%H-\%M`"
   echo "Slave status report on $(date +%m-%d-%Y-%H:%M)" >> $log_file
   echo "Error in slave on $server_name" >> $log_file
   if [ "$sql_thread_running" = "No" ]; then
                echo "SQL Thread not running" >> $log_file
   fi

   if [ "$io_thread_running" = "No" ]; then
     echo "IO thread not running" >> $log_file
   fi

   if [ $seconds_late -gt 0 ]; then #formattting how the latency of the slave behind master should be displayed
     display_late="$seconds_late seconds"
      if [ $seconds_late -gt 60 ]; then
         display_late="$display_late = $(($seconds_late/60)) minutes"
      fi
      if [ $seconds_late -gt 3600 ]; then
        display_late="$display_late = $(($seconds_late/3600)) hours"
      fi
     echo "slave is behind master by $display_late" >> $log_file
   fi

while read line
 do
  name=$line
  MAIL_TXT+="\n $name";
 done < $log_file

 MAIL_TXT+="\n \n $VERSION";
 echo -e $MAIL_TXT |  /usr/sbin/sendmail -t

echo `date +\%Y\%m\%d-\%H:\%M` " : Slave not running, alerts sent to the admins..." >> $log_file
else
echo `date +\%Y\%m\%d-\%H:\%M` " : slave is running normally, no problem detected :)" >> $log_file


fi
