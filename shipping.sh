#!/bin/bash

START_TIME=$(date +%s)
echo "Script Started at:$(date)"
#Check if you are running with root or not
USER_ID=$(id -u) #if the value is 0 then you are running with root 
SCRIPT_DIR=$PWD
LOG_DIR="/var/log/roboshop_logs"
SCRIPT_NAME="$(echo $0 | cut -d "." -f1)"
LOG_FILE="$LOG_DIR/$SCRIPT_NAME.log"

echo "Please enter ROOT password"
read -s ROOT_PASSWORD

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

#Shipping setup

dnf install maven -y &>>$LOG_FILE
VALIDATE $? "Installing maven"

id roboshop
if [ $? -ne 0 ]
then
    useradd --system --home /app --shell /sbin/nologin --comment "Roboshopuser" roboshop
    VALIDATE $? "Roboshop User has been created"
else
    echo "user is already present"
fi

mkdir -p /app
cd /app
rm -rf *
curl -o /tmp/shipping.zip https://roboshop-artifacts.s3.amazonaws.com/shipping-v3.zip &>>$LOG_FILE
unzip /tmp/shipping.zip &>>$LOG_FILE
VALIDATE $? "Unzipping the shipping package"

mvn clean package &>>$LOG_FILE
VALIDATE $? "Installing java build package"

mv target/shipping-1.0.jar shipping.jar 
VALIDATE $? "rename and moving the jar file"

cp $SCRIPT_DIR/shipping.service /etc/systemd/system/shipping.service
VALIDATE $? "Copying the systemd configuration"

systemctl daemon-reload
systemctl enable shipping
systemctl start shipping
VALIDATE $? "Enabling and starting shipping"

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

END_TIME=$(date +%s)
echo "Script Completed at:$(date)"
TOTAL_TIME=$(($END_TIME - $START_TIME))
echo "Total time taken: $TOTAL_TIME seconds"
