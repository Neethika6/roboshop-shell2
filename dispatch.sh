#!/bin/bash

source ./common.sh
appname=dispatch

check_root

app_setup

#dispatch setup

dnf install golang -y &>>$LOG_FILE
VALIDATE $? "Installing GO"

go mod init dispatch 
go get 
go build
VALIDATE $? "Installing dependencies"

systemd_setup

check_time
