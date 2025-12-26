#!/bin/sh
#
# @Time    : 2022-10-21
# @Author  : wendy
# @Desc    : ssh login banner
export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
# shopt -q login_shell && : || return 0
upSeconds="$(cut -d. -f1 /proc/uptime)"
# os
upSeconds="$(cut -d. -f1 /proc/uptime)"
secs=$((${upSeconds}%60))
mins=$((${upSeconds}/60%60))
hours=$((${upSeconds}/3600%24))
days=$((${upSeconds}/86400))
UPTIME_INFO=$(printf "%d days, %02dh %02dm %02ds" "$days" "$hours" "$mins" "$secs")
if [ -f /etc/redhat-release ] ; then
    PRETTY_NAME=$(< /etc/redhat-release)
elif [ -f /etc/debian_version ]; then
   DIST_VER=$(</etc/debian_version)
   PRETTY_NAME="$(grep PRETTY_NAME /etc/os-release | sed -e 's/PRETTY_NAME=//g' -e  's/"//g') ($DIST_VER)"
else
    PRETTY_NAME=$(cat /etc/*-release | grep "PRETTY_NAME" | sed -e 's/PRETTY_NAME=//g' -e 's/"//g')
fi
if [[ -d "/system/app/" && -d "/system/priv-app" ]]; then
    model="$(getprop ro.product.brand) $(getprop ro.product.model)"
elif [[ -f /sys/devices/virtual/dmi/id/product_name ||
        -f /sys/devices/virtual/dmi/id/product_version ]]; then
    model="$(< /sys/devices/virtual/dmi/id/product_name)"
    model+=" $(< /sys/devices/virtual/dmi/id/product_version)"
elif [[ -f /sys/firmware/devicetree/base/model ]]; then
    model="$(< /sys/firmware/devicetree/base/model)"
elif [[ -f /tmp/sysinfo/model ]]; then
    model="$(< /tmp/sysinfo/model)"
fi
MODEL_INFO=${model}
KERNEL=$(uname -srmo)
USER_NUM=$(who -u | wc -l)
RUNNING=$(ps ax | wc -l | tr -d " ")
# disk
totaldisk=$(df -h -x devtmpfs -x tmpfs -x debugfs -x aufs -x overlay --total 2>/dev/null | tail -1)
disktotal=$(awk '{print $2}' <<< "${totaldisk}")
diskused=$(awk '{print $3}' <<< "${totaldisk}")
diskusedper=$(awk '{print $5}' <<< "${totaldisk}")
DISK_INFO="\033[0;33m${diskused}\033[0m of \033[1;34m${disktotal}\033[0m disk space used (\033[0;33m${diskusedper}\033[0m)"
# cpu
cpu=$(awk -F':' '/^model name/ {print $2}' /proc/cpuinfo | uniq | sed -e 's/^[ \t]*//')
cpun=$(grep -c '^processor' /proc/cpuinfo)
cpuc=$(grep '^cpu cores' /proc/cpuinfo | tail -1 | awk '{print $4}')
cpup=$(grep '^physical id' /proc/cpuinfo | wc -l)
CPU_INFO="${cpu} ${cpup}P ${cpuc}C ${cpun}L"
# get the load averages
read one five fifteen rest < /proc/loadavg
LOADAVG_INFO="\033[0;33m${one}\033[0m / ${five} / ${fifteen} with \033[1;34m$(( cpun*cpuc ))\033[0m core(s) at \033[1;34m$(grep '^cpu MHz' /proc/cpuinfo | tail -1 | awk '{print $4}')\033 MHz"
# mem
MEM_INFO="$(cat /proc/meminfo | awk '/MemTotal:/{total=$2/1024/1024;next} /MemAvailable:/{use=total-$2/1024/1024; printf("\033[0;33m%.2fGiB\033[0m of \033[1;34m%.2fGiB\033[0m RAM used (\033[0;33m%.2f%%\033[0m)",use,total,(use/total)*100);}')"
# network
# extranet_ip=" and $(curl -s http://members.3322.org/dyndns/getip)"
IP_INFO="$(curl -s http://members.3322.org/dyndns/getip)"
# Container info
CONTAINER_INFO="$(sudo /usr/bin/crictl ps -a -o yaml 2> /dev/null | awk '/^  state: /{gsub("CONTAINER_", "", $NF) ++S[$NF]}END{for(m in S) printf "%s%s:%s ",substr(m,1,1),tolower(substr(m,2)),S[m]}')Images:$(sudo /usr/bin/crictl images -q 2> /dev/null | wc -l)"
# info
echo -e "
 \033[0;1;31m内存\033[0m.................:  ${MEM_INFO}
 \033[0;1;31m平均负载\033[0m.............:  ${LOADAVG_INFO}
 \033[0;1;31m处理器\033[0m...............:  ${CPU_INFO}
 \033[0;1;31m磁盘使用情况\033[0m.........:  ${DISK_INFO}
 \033[0;1;31m不间断运行时长\033[0m...........:  ${UPTIME_INFO} :.............: \033[0;1;31m不间断运行时长\033[0m
\033[0;32m############################################################################
  _____   _____      _____                        Wendy镜像
 | ___ \ | __  \    / ___/___  ______   _____  _____
 ||  / / ||  / /____\__ \/ _ \/ ___/ | / / _ \/ ___/ \033[0m      \033[0;1;31m（检测专用）\033\033[0;32m
 ||_/ /  ||_/ /____/__/ /  __/ /   | |/ /  __/ /
 |___/   |___/    /____/\___/_/    |___/\___/_/     \033[0m${PRETTY_NAME}\033[0;32m
-------------------------------------------------------------------------------
 \033[0;1;31mI P 地 址\033[0m..............:      \033[1;34m${IP_INFO}\033[0m     :...............\033[0;1;31mI P 地 址\033[0m	 
 \033[0;32m------------------------------------------------------------------------------\033[0;32m
 \033[0;1;31m操作系统\033[0m........:  ${PRETTY_NAME}  :.........: \033[0;1;31m操作系统\033[0m	
 \033[0;32m------------------------------------\033[0m\033[0;1;31mby doudou\033[0m\033[0;32m----------------\033[0m
\033[0;1;32m##############################################################################\033[0m
\033[0;1;32m#\033[0m                 \033[0;1;32m查公网IP                                                          
\033[0;1;32m#\033[0m \033[0;1;31mcurl -s http://members.3322.org/dyndns/getip\033[0m 
\033[0;1;32m#\033[0m                \\033[0;1;32m服务启停命令\033[0m                                                          
\033[0;1;32m#\033[0m            \033[0;1;36msystemctl stop firewalld                                           
\033[0;1;32m#\033[0m            \033[0;1;36msystemctl enable iptables                                            
\033[0;1;32m#\033[0m            \033[0;1;36msystemctl disable firewalld                                        
\033[0;1;32m############################################################################\033[0m

 "
