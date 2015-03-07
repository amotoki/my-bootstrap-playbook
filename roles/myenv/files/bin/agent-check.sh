#!/bin/sh

USERNAME=`whoami`

NUM=`ps -ef | grep ssh-agent | grep -v grep | grep $USERNAME | wc -l`
if [ $NUM -eq 1 ]; then
  ST=`ps -ef | grep ssh-agent | grep -v grep | grep $USERNAME`
  AGENT_PID=$(echo $ST | awk '{print $2;}')
  SOCKFILE=$(ls -l /tmp/ssh-*/agent.[0-9]* | grep $USERNAME | sed -e 's/^.*\(\/tmp\/ssh-.*\)/\1/')
  echo "echo SOCKFILE=$SOCKFILE;"
  echo "echo AGENT_PID=$AGENT_PID;"
  if [ $? -ne 0 ]; then
    echo echo 'Cannot find SSH Agent Socket!!! Please check manually.'
    exit 1
  fi
  echo "SSH_AUTH_SOCK=$SOCKFILE; export SSH_AUTH_SOCK;"
  echo "SSH_AGENT_PID=$AGENT_PID; export SSH_AGENT_PID;"
  echo echo agent pid is $AGENT_PID
  exit 0
elif [ $NUM -gt 1 ]; then
  echo 'echo More than one ssh-agent for you!!! Please check manually.'
  exit 2
else
  #echo echo 'No ssh-agent found. Execute ssh-agent!!'
  /usr/bin/ssh-agent
  echo echo 'No ssh-agent found and started new ssh-agent.'
  exit 3
fi
