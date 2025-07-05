#!/bin/bash

source ./common.sh
appaname=mongodb

check_root

#MONGODB SETUP
echo "Copy MONGO.repo file to the repository directory"
cp $SCRIPT_DIR/mongo.repo /etc/yum.repos.d/mongo.repo
VALIDATE $? "Copying the repository file"

echo "Installing the MONGODB"
dnf install mongodb-org -y &>>$LOG_FILE
VALIDATE $? "Installation of MONGODB"

echo "Enable and start the mongodb instance"
systemctl enable mongod 
VALIDATE $? "Enabling MONGODB"

systemctl start mongod
VALIDATE $? "Started MONGODB"

#Update the mongod.conf file to open the port 

sed -i 's/127.0.0.1/0.0.0.0/g' /etc/mongod.conf
VALIDATE $? "Updated the port in conf file"

systemctl restart mongod
VALIDATE $? "Restarted MONGODB"

check_time



