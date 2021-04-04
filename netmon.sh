#!/bin/bash
# Minimal Network Monitor, by Ignacio Agulló under GPLv3.0
# 25-8-2020: Created
# 27-9-2020: Last update
# This is a tool for dealing with faulty Internet connections that drop while being nominally up.
# This script monitors that the Internet connection is really working by frequently reading from Internet the public IP address.
# WARNING: In order to work, the script needs the address of a public Internet resource that returns the public IP address.
# WARNING: This address must be assigned to variable 'recurso' right after the "Start" comment.  IT WON'T WORK WITHOUT IT.
# Sintax: netmon.sh [timeout]
# The timeout is for the wait on the IP address, in seconds; default value is 10.
# It stops on receiving any of the signals SIGHUP SIGINT SIGTERM
# SIGHUP: Notification of the terminal being closed.
# SIGINT: Interrupt request sent by the user (Ctrl+C).
# SIGTERM: Termination request sent by the system.
#Signal trap
trap terminar SIGHUP SIGINT SIGTERM
#Functions
function terminar {
	continuar=false
# In case that there are child processes, kill them:
	if [[ $pid_echo ]]
	then 
      if [[ $(ps --no-headers -p "$pid_echo") ]]
	  then
	    kill "$pid_echo"
	  fi
	fi
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
pid_echo=
pid_sleep=
timeout=10
if [[ $# -gt 0 ]]
then
  if [[ "$1" =~ ^[0-9]+([.][0-9]+)?$ ]]
  then
    timeout=$1
  fi
fi
echo 'Minimal Network Monitor, by Ignacio Agulló under GPLv3.0'
echo 'Interface Data'
ifconfig -a
echo 'Date       Time  Public IP'
continuar=true
#Loop
while $continuar
do
  sleep 60 &
  pid_sleep=$!
  echo `date '+%F %H:%M' ; curl -s -m $timeout --retry 0 $recurso` &
  pid_echo=$!
  wait $pid_echo
  pid_echo=
  wait $pid_sleep
  pid_sleep=
done
# End
echo 
echo `date '+%F %H:%M' ` 'End of execution'
