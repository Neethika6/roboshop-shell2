#!/bin/bash

START_TIME=$(date +%s)
echo "Script Started at:$(date)"
#Check if you are running with root or not
USER_ID=$(id -u) #if the value is 0 then you are running with root 
SCRIPT_DIR=$PWD
LOG_DIR="/var/log/roboshop_logs"
SCRIPT_NAME="$(echo $0 | cut -d "." -f1)"
LOG_FILE="$LOG_DIR/$SCRIPT_NAME.log"

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

#dispatch setup

dnf install golang -y &>>$LOG_FILE
VALIDATE $? "Installing GO"

id roboshop
if [ $? != 0 ]
then
    useradd --system --home /app --shell /sbin/nologin --comment "ROBOSHOP USER" roboshop
    VALIDATE $? "Roboshop user created"
else
    echo "user is already present"
fi

mkdir -p /app
cd /app
rm -rf *
curl -o /tmp/dispatch.zip https://roboshop-artifacts.s3.amazonaws.com/dispatch-v3.zip &>>$LOG_FILE
unzip /tmp/dispatch.zip
VALIDATE $? "Unzipping dispatch zip"

go mod init dispatch 
go get 
go build
VALIDATE $? "Installing dependencies"

cp $SCRIPT_DIR/dispatch.service /etc/systemd/system/dispatch.service
VALIDATE $? "Copying service file"


systemctl daemon-reload
systemctl enable dispatch 
systemctl start dispatch
VALIDATE $? "enabling and starting dispatch"

END_TIME=$(date +%s)
echo "Script Completed at:$(date)"
TOTAL_TIME=$(($END_TIME - $START_TIME))
echo "Total time taken: $TOTAL_TIME seconds"
