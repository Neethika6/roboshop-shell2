#!/bin/bash

source ./common.sh
appname=shipping

echo "Please enter ROOT password"
read -s ROOT_PASSWORD

check_root

app_setup

maven_setup

systemd_setup

dnf install mysql -y &>>$LOG_FILE
VALIDATE $? "Installing mysql client"

mysql -h mysql.devopshyn.fun -u root -p$ROOT_PASSWORD -e "use cities;"

if [ $? != 0 ]
then

    mysql --host mysql.devopshyn.fun -uroot -p$ROOT_PASSWORD < /app/db/schema.sql &>>$LOG_FILE
    VALIDATE $? "Loading Schema"

    mysql --host mysql.devopshyn.fun -uroot -p$ROOT_PASSWORD < /app/db/app-user.sql &>>$LOG_FILE
    VALIDATE $? "Loading App-user"

    mysql --host mysql.devopshyn.fun -uroot -p$ROOT_PASSWORD < /app/db/master-data.sql &>>$LOG_FILE
    VALIDATE $? "Loading master data"
else
    echo "data is already loaded"
fi

systemctl restart shipping
VALIDATE $? "Shipping restart"

check_time
