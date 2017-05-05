#!/bin/bash

if [ -z "$1" ]; then
  echo "$0 (apache|runserver) [nocompress]"
  exit 1
fi

cd /opt/stack/horizon

find horizon -name '*.pyc' | xargs rm
find openstack_dashboard -name '*.pyc' | xargs rm

DJANGO_SETTINGS_MODULE=openstack_dashboard.settings python manage.py collectstatic --noinput
if [ "$2" != 'nocompress' ]; then
  DJANGO_SETTINGS_MODULE=openstack_dashboard.settings python manage.py compress --force
fi

if [ "$1" = "runserver" ]; then
  tox -e runserver -- 0.0.0.0:8000
else
  sudo service apache2 reload
fi
