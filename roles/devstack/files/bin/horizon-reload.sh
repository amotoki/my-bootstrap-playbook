#!/bin/bash

cd /opt/stack/horizon

DJANGO_SETTINGS_MODULE=openstack_dashboard.settings python manage.py collectstatic --noinput
DJANGO_SETTINGS_MODULE=openstack_dashboard.settings python manage.py compress --force

sudo service apache2 reload
