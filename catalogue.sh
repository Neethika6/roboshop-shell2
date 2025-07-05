#!/bin/bash

source ./common.sh
appname=catalogue

check_root

app_setup

nodejs_setup

systemd_setup

#Install mongodb client to load the data into mongodb"
cp $SCRIPT_DIR/mongo.repo /etc/yum.repos.d/mongo.repo
VALIDATE $? "Copying mongodb repo"

dnf install mongodb-mongosh -y &>>$LOG_FILE
VALIDATE $? "Installed MONGODB Client"

STATUS=$(mongosh --host mongodb.devopshyn.fun --eval 'db.getMongo().getDBNames().indexOf("catalogue")')
if [ $STATUS -le 0 ]
then
    mongosh --host mongodb.devopshyn.fun </app/db/master-data.js &>>$LOG_FILE
    VALIDATE $? "Data loaded into MONGODB"
else
    echo "Data is already in the DB"
fi

check_time



