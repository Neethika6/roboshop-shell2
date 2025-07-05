#!/bin/bash

START_TIME=$(date +%s)
echo "Script Started at:$(date)"
#Check if you are running with root or not
USER_ID=$(id -u) #if the value is 0 then you are running with root 
SCRIPT_DIR=$PWD
LOG_DIR="/var/log/roboshop_logs"
SCRIPT_NAME="$(echo $0 | cut -d "." -f1)"
LOG_FILE="$LOG_DIR/$SCRIPT_NAME.log"

echo "Please enter RABBITMQ password"
read -s RABBITMQ_PASSWORD

#Creates a dir if not present -p will not throw error if the dir is already present
mkdir -p /var/log/roboshop_logs

#if the value is 0 then you are running with root
if [ $USER_ID == 0 ]
then
    echo "YOU ARE IN ROOT" | tee -a $LOG_FILE
else
    echo "ERROR:PLEASE SWITCH TO ROOT" | tee -a $LOG_FILE
    exit 1  #Script will not execute any lines if you are not in the ROOT
fi

#Function to check if the commands were executed correctly or not
VALIDATE()
{
    if [ $1 == 0 ]
    then 
        echo "$2...SUCCESS" | tee -a $LOG_FILE
    else
        echo "$2...Failed" | tee -a $LOG_FILE
    fi
}

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

END_TIME=$(date +%s)
echo "Script Completed at:$(date)"
TOTAL_TIME=$(($END_TIME - $START_TIME))
echo "Total time taken: $TOTAL_TIME seconds"