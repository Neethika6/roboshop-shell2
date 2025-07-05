#!/bin/bash

source ./common.sh
appname=user

check_root

app_setup

nodejs_setup

systemd_setup

check_time