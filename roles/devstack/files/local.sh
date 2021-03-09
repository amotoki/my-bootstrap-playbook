#!/bin/bash -ex

# Clear existing OpenStack related envvars
for x in `env | grep ^OS_ | cut -d = -f 1`; do unset $x; done
export OS_CLOUD=devstack
env | grep OS_
for pubkey in $HOME/.ssh/id_rsa.pub $HOME/.ssh/id_dsa.pub; do
  if [ -f $pubkey ]; then
    openstack keypair create --public-key $pubkey mykey
  fi
done

########################
# Cleanup after stack.sh
########################

# Remove existing VMs created by past run of devstack.
# Otherwise, nova-compute fails to create new servers.
# NOTE: this is unnecessary for victoria or later.
export LC_ALL=C
export LANG=C
for x in `virsh list --all | tail -n +3 | awk '{print $2;}' `; do
  virsh destroy $x
  virsh undefine $x
done

# Ajdust ownership of someo files under openstack_dashboard
# so that re-running stack.sh does not fail.
find /opt/stack/horizon/openstack_dashboard -user root | xargs sudo chown `whoami`:
