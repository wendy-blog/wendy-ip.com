#!/bin/bash
# 确保系统为CentOS 7和x86_64架构
if [ -f /etc/redhat-release ]; then
    release=`cat /etc/redhat-release | awk '{print $4}'`
    if [ $release != "7." ]; then
        echo "This script only support CentOS 7"
        exit 1
    fi
fi
 
if [ `uname -m` != "x86_64" ]; then
    echo "This script only support x86_64 architecture"
    exit 1
fi
