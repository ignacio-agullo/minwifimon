#!/bin/bash
# Minimal IP Monitor, by Ignacio Agulló under GPLv3.0
# 29-08-2020: Created
# 01-11-2020: Last update
# This is a tool for dealing with faulty Internet connections that drop while being nominally up.
# This script monitors that the Internet connection is really working by frequently reading from Internet the public IP address.
# WARNING: In order to work, the script needs the address of a public Internet resource that returns the public IP address.
# WARNING: This address must be assigned to variable 'recurso' right after the "Start" comment.  IT WON'T WORK WITHOUT IT.
# Depending on the public IP address read, the script does:
# -If the IP address is blank and the Wi-Fi is switched on, it switches it off and then on again.
# -If the IP address is blank and the Wi-Fi is switched off, it switches it on.
# -If the IP address matches that of the previous read, it doesn't register anything.
# -If the IP address is different from the previous read, the change is registered.
# Sintax: ipmon.sh [timeout]
# The timeout is for the wait on the IP address, in seconds; default value is 10.
# It stops on receiving any of the signals SIGHUP SIGINT SIGTERM
# SIGHUP: Notification of the terminal being closed.
# SIGTERM: Termination request sent by the system.
# SIGINT: Interrupt request sent by the user (Ctrl+C).
#Signal trap
trap terminar SIGHUP SIGINT SIGTERM
#Functions
function terminar {
	continuar=false
# In case that there are child processes, kill them:
	if [[ $pid_sleep ]]
	then 
      if [[ $(ps --no-headers -p "$pid_sleep") ]]
	  then
	    kill "$pid_sleep"
	  fi
	fi
}
#Start
recurso=
pid_sleep=
timeout=10
if [[ $# -gt 0 ]]
then
  if [[ "$1" =~ ^[0-9]+([.][0-9]+)?$ ]]
  then
    timeout=$1
  fi
fi
echo 'Minimal IP Monitor, by Ignacio Agulló under GPLv3.0'
echo 'Interface Data'
ifconfig -a
echo 'Date       Time     Public IP'
#First iteration
sleep 30 &
pid_sleep=$!
ip_nova=$(curl -s -m $timeout --retry 0 $recurso)
if [ -z $ip_nova ]
then
  radio=$(nmcli -f WIFI -t -c no r)
  if [ "$radio" = "activado" ]
# If no network connection:
# -If the Wi-Fi is on, switch it off and on again.
# -If the Wi-Fi is off, switch if on.
  then
    echo `date '+%F %H:%M:%S'`' No network access. Wi-Fi connected; reconnecting.'
    nmcli radio wifi off
  else
    echo `date '+%F %H:%M:%S'`' No network access. Wi-Fi disconnected; connecting.'
  fi
  nmcli radio wifi on
else
# Detect HTTP error
  if [[ $ip_nova = *title* ]]
  then
    ip_nova="${ip_nova#*<title>}"
    ip_nova="unknown because of error ${ip_nova%%</title>*}"
  fi
  echo `date '+%F %H:%M:%S'`" Connected with public IP $ip_nova"
fi
wait $pid_sleep
pid_sleep=
continuar=true
#Loop
while $continuar
do
  sleep 30 &
  pid_sleep=$!
  ip_vella=$ip_nova
  ip_nova=$(curl -s -m $timeout --retry 0 $recurso)
# Detect HTTP error
  if [[ $ip_nova = *title* ]]
  then
    ip_nova="${ip_nova#*<title>}"
    ip_nova="unknown because of error ${ip_nova%%</title>*}"
  fi
  radio=$(nmcli -f WIFI -t -c no r)
  if [ "$ip_vella" = "$ip_nova" ]
# Depending of the comparison of the public IP address with the previous one, it is done:  
# -If the IP address is the same as the last time, nothing is registered.
# -If the IP address is differente, it is registered the connection or lack thereof.
# Besides, if there is no connection to the network:
# -If the Wi-Fi is on, switch it off and on again.
# -If the Wi-Fi is off, switch if off.
  then
    if [ -z $ip_nova ]
    then
      if [ "$radio" = "activado" ]
      then
        nmcli radio wifi off
      fi
      nmcli radio wifi on
    fi
  else
    if [ -z $ip_nova ]
    then
      if [ "$radio" = "activado" ]
      then
        echo `date '+%F %H:%M:%S'`' No network access. Wi-Fi connected; reconnecting.'
        nmcli radio wifi off
      else
        echo `date '+%F %H:%M:%S'`' No network access. Wi-Fi disconnected; connecting.'
      fi
      nmcli radio wifi on
    else
      echo `date '+%F %H:%M:%S'`" Connected with public IP $ip_nova"
    fi
  fi
  wait $pid_sleep
  pid_sleep=
done
# End
echo 
echo `date '+%F %H:%M:%S' ` 'End of execution'

