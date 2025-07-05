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

#cart setup
dnf module disable nodejs -y &>>$LOG_FILE
VALIDATE $? "Disbaling default nodejs"

dnf module enable nodejs:20 -y &>>$LOG_FILE
VALIDATE $? "Enabling nodejs version:20"

dnf install nodejs -y &>>$LOG_FILE
VALIDATE $? "Installing nodejs version:20"

id roboshop
if [ $? -ne 0 ]
then
    useradd --system --home /app --shell /sbin/nologin --comment "Roboshop user" roboshop
    VALIDATE $? "Creating System user"
else
    echo "ROboshop user is already present"
fi

mkdir -p /app
cd /app
rm -rf *
curl -o /tmp/cart.zip https://roboshop-artifacts.s3.amazonaws.com/cart-v3.zip &>>$LOG_FILE
unzip /tmp/cart.zip
VALIDATE $? "Unzipping of cart package"

npm install &>>$LOG_FILE
VALIDATE $? "Installing npm package"

cp $SCRIPT_DIR/cart.service /etc/systemd/system/cart.service
VALIDATE $? "copying cart service file in systemd"

systemctl daemon-reload
systemctl enable cart
systemctl start cart
VALIDATE $? "Enabling and starting cart"

END_TIME=$(date +%s)
echo "Script Completed at:$(date)"
TOTAL_TIME=$(($END_TIME - $START_TIME))
echo "Total time taken: $TOTAL_TIME seconds"
