#!/bin/sh

ENV=${ENV:-$(hostname)}

if [ -z "$2" ]; then
  echo "Usage: $0 <host> <playbook> [playbook options...]"
  exit 1
fi

set -o xtrace

HOST=$1
shift
PLAYBOOK=$1
shift

INVENTORY=inventory/${ENV}/hosts
if [ ! -f $INVENTORY ]; then
  echo "Please create inventory for $ENV or run ansible-playbook directly."
  exit 1
fi

ansible-playbook -i $INVENTORY -e host=$HOST $PLAYBOOK "$@"
