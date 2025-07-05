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

check_root()
{
    #if the value is 0 then you are running with root
    if [ $USER_ID == 0 ]
    then
        echo "YOU ARE IN ROOT" | tee -a $LOG_FILE
    else
        echo "ERROR:PLEASE SWITCH TO ROOT" | tee -a $LOG_FILE
        exit 1  #Script will not execute any lines if you are not in the ROOT
    fi
}

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

check_time()
{
    END_TIME=$(date +%s)
    echo "Script Completed at:$(date)"
    TOTAL_TIME=$(($END_TIME - $START_TIME))
    echo "Total time taken: $TOTAL_TIME seconds"
}

nodejs_setup()
{
    echo "Disable the existing default NODEJS"
    dnf module disable nodejs -y &>>$LOG_FILE
    VALIDATE $? "Diabled Default NODEJS"

    echo "Enable the NODEJS version20"
    dnf module enable nodejs:20 -y &>>$LOG_FILE
    VALIDATE $? "Enabled NODEJS VERSION:20"

    echo "Installating NODEJS"
    dnf install nodejs -y &>>$LOG_FILE
    VALIDATE $? "Installed NODEJS"

    npm install &>>$LOG_FILE
    VALIDATE $? "Installing the build package of nodejs"
}

app_setup()
{
    mkdir -p /app
    cd /app
    rm -rf *
    curl -o /tmp/$appname.zip https://roboshop-artifacts.s3.amazonaws.com/$appname-v3.zip &>>$LOG_FILE
    unzip /tmp/$appname.zip
    VALIDATE $? "Copying and unzipping the $appname file"

    id roboshop
    if [ $? -ne 0 ]
    then
        useradd --system --home /app --shell /sbin/nologin --comment "Roboshop User" roboshop
        VALIDATE $? "Creating system user"
    else
        echo "Roboshop user is already present" 
    fi    
}

systemd_setup()
{
    cp $SCRIPT_DIR/$appname.service /etc/systemd/system/$appname.service
    VALIDATE $? "Copying service file to the Systemd path"

    systemctl daemon-reload
    systemctl enable $appname
    systemctl start $appname
    VALIDATE $? "Started $appname"
}

mysql_setup()
{
    dnf install mysql-server -y &>>$LOG_FILE
    VALIDATE $? "Install $appname"

    systemctl enable mysqld
    systemctl start mysqld
    VALIDATE $? "Enable and start $appname"

    echo "Enter root passowrd"
    read -s ROOT_PASS

    mysql_secure_installation --set-root-pas $ROOT_PASS
}

maven_setup()
{
    dnf install maven -y &>>$LOG_FILE
    VALIDATE $? "Installing maven"


    mvn clean package &>>$LOG_FILE
    VALIDATE $? "Installing java build package"

    cd /app
    mv target/shipping-1.0.jar shipping.jar 
    VALIDATE $? "rename and moving the jar file"
}