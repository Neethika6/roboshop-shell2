#!/bin/bash

source ./common.sh
appname=redis

check_root

#Redis setup
dnf module disable redis -y &>>$LOG_FILE
VALIDATE $? "Disbale the default redis"

dnf module enable redis:7 -y &>>$LOG_FILE
VALIDATE $? "Enable redis version:7"

dnf install redis -y &>>$LOG_FILE
VALIDATE $? "Install redis version:7"

sed -i -e 's/127.0.0.1/0.0.0.0/g' -e '/protected-mode/ c protected-mode no' /etc/redis/redis.conf
VALIDATE $? "Updating the redis.conf file"

systemctl enable redis
systemctl start redis
VALIDATE $? "Enable ans start redis"

check_time