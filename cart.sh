#!/bin/bash

source ./common.sh
appname=cart

check_root

app_setup

nodejs_setup

systemd_setup

check_time
