#!/bin/bash
# Minimal Network Monitor from Startup, by Ignacio Agulló under GPLv3.0
# 25-8-2020: Creado
# 27-9-2020: Última actualización.
# This is a tool for dealing with faulty Internet connections that drop while being nominally up.
# This script monitors that the Internet connection is really working by frequently reading from Internet the public IP address.
# WARNING: In order to work, the script needs the address of a public Internet resource that returns the public IP address.
# WARNING: This address must be assigned to variable 'recurso' right after the "Start" comment.  IT WON'T WORK WITHOUT IT.
# Sintax: netmon_startup.sh [timeout]
# The timeout is for the wait on the IP address, in seconds; default value is 10.
# It stops on receiving any of the signals SIGHUP SIGTERM
# SIGHUP: Notification of the terminal being closed.
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
data=`date '+%F_%H-%M-%S'`
rexistro="`dirname "$(readlink -f "$0")"`/rede_$data.log"
if [ -e $rexistro ]
then
  >&2 echo "Minimal Network Monitor from Startup: Error, the file $rexistro already exists"
else
  echo 'inimal Network Monitor from Startup, by Ignacio Agulló under GPLv3.0' > $rexistro
  echo 'Interface Data' >> $rexistro
  ifconfig -a >> $rexistro
  echo 'Date       Time  Public IP' >> $rexistro
  continuar=true
#Bucle
  while $continuar
  do
    sleep 60 &
    pid_sleep=$!
    echo `date '+%F %H:%M' ; curl -s -m $timeout --retry 0 $recurso` >> $rexistro &
    pid_echo=$!
    wait $pid_echo
    pid_echo=
    wait $pid_sleep
    pid_sleep=
  done
# Finalización
  echo 
  echo `date '+%F %H:%M' ` 'Fin de execución' >> $rexistro
fi

