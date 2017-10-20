#!/bin/bash

# extra-install-option is used only when runserver is used.
# It is useful when installing horizon plugins into runserver venv like:
# horizon-reload.sh runserver nocompress -e ~/work/neutron-fwaas-dashboard -e ~/work/neutron-vpnaas-dashboard

if [ -z "$1" ]; then
  echo "$0 (apache|runserver) [nocompress] [extra-install-option...]"
  exit 1
fi

case "$1" in
  apache|runserver)
    MODE=$1
    ;;
  *)
    echo "'mode' must be 'apache' or 'runserver'."
    exit 1
    ;;
esac
shift

USE_COMPRESS=1
if [ -n "$1" -a "$1" = "nocompress" ]; then
  USE_COMPRESS=0
  shift
fi

echo "MODE=$MODE"
echo "USE_COMPRESS=$USE_COMPRESS"
echo "Extra args: $@"
echo "Arg length: $#"

cd /opt/stack/horizon

find horizon -name '*.pyc' | xargs rm
find openstack_dashboard -name '*.pyc' | xargs rm

find horizon -name '__pycache__' | xargs rm -rf
find openstack_dashboard -name '__pycache__' | xargs rm -rf

DJANGO_SETTINGS_MODULE=openstack_dashboard.settings python manage.py collectstatic --noinput
if [ "$USE_COMPRESS" = "1" ]; then
  DJANGO_SETTINGS_MODULE=openstack_dashboard.settings python manage.py compress --force
fi

if [ "$MODE" = "runserver" ]; then
  if [ $# -gt 0 ]; then
    tox -e runserver --notest
    .tox/runserver/bin/pip install "$@"
  fi
  tox -e runserver -- 0.0.0.0:8000
else
  sudo service apache2 reload
fi
