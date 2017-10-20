#!/bin/bash -ex

export OS_CLOUD=devstack
env | grep OS_
if [ -f /home/ubuntu/.ssh/id_dsa.pub ]; then
  openstack keypair create --public-key $HOME/.ssh/id_dsa.pub mykey
elif [ -f $HOME/.ssh/id_rsa.pub ]; then
  openstack keypair create --public-key $HOME/.ssh/id_rsa.pub mykey
fi

# Disable horizon using apache2
sed -i -e 's|^\(WEBROOT="/dashboard/"\)|# \1|' /opt/stack/horizon/openstack_dashboard/local/local_settings.py
sed -i -e 's|^\(COMPRESS_OFFLINE=True\)|# \1|' /opt/stack/horizon/openstack_dashboard/local/local_settings.py
