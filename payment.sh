#!/bin/bash

source ./common.sh
appname="payment"

check_root

app_setup

#PAYMENT SETUP
dnf install python3 gcc python3-devel -y &>>$LOG_FILE
VALIDATE $? "Installing python"

pip3 install -r requirements.txt &>>$LOG_FILE
VALIDATE $? "Installing pip"

systemd_setup

check_time
