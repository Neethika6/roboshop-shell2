#!/bin/bash

source ./common.sh
appname="rabbitmq"

echo "Please enter RABBITMQ password"
read -s RABBITMQ_PASSWORD

check_root

#Rabbitmq setup

cp $SCRIPT_DIR/rabbitmq.repo /etc/yum.repos.d/rabbitmq.repo
VALIDATE $? "Copying rabbit mq repo in teh repository directory"

dnf install rabbitmq-server -y &>>$LOG_FILE
VALIDATE $? "Installing rabbit MQ"

systemctl enable rabbitmq-server
systemctl start rabbitmq-server
VALIDATE $? "Enabling and starting rabbitmq"

rabbitmqctl add_user roboshop $RABBITMQ_PASSWORD
rabbitmqctl set_permissions -p / roboshop ".*" ".*" ".*"

check_time