#!/bin/bash

# extra-install-option is used only when runserver is used.
# It is useful when installing horizon plugins into runserver venv like:
# horizon-reload.sh runserver nocompress -e ~/work/neutron-fwaas-dashboard -e ~/work/neutron-vpnaas-dashboard

if [ -z "$1" ]; then
  echo "$0 (apache|runserver|runserver-py35dj20) [nocompress] [extra-install-option...]"
  exit 1
fi

case "$1" in
  apache|apache2|runserver|runserver-py35dj20|runserver-py35)
    MODE=$1
    ;;
  *)
    echo "'mode' must be (apache|runserver|runserver-py35dj20)."
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

case "$MODE" in
  runserver|runserver-py35*)
    cd $HOME/work/horizon
    ;;
  apache|apache2)
    cd /opt/stack/horizon
    ;;
esac

for module in horizon openstack_auth openstack_dashboard; do
  for lang in ja; do
    for domain in django djangojs; do
      catalog=$module/locale/$lang/LC_MESSAGES/$domain
      if [ -f $catalog.po ]; then
        msgfmt -o $catalog.mo $catalog.po
      fi
    done
  done
done

find horizon -name '*.pyc' | xargs --no-run-if-empty rm
find openstack_dashboard -name '*.pyc' | xargs --no-run-if-empty rm

find horizon -name '__pycache__' | xargs --no-run-if-empty rm -rf
find openstack_dashboard -name '__pycache__' | xargs --no-run-if-empty rm -rf

handle_static_files() {
  DJANGO_SETTINGS_MODULE=openstack_dashboard.settings $PYTHON manage.py collectstatic --noinput
  if [ "$USE_COMPRESS" = "1" ]; then
    DJANGO_SETTINGS_MODULE=openstack_dashboard.settings $PYTHON manage.py compress --force
  fi
}

# Update local_settings before compressing static files
case "$MODE" in
  runserver|runserver-py35*)
    sed -e 's/^#* *_USE_RUNSERVER = .*/_USE_RUNSERVER = True/' -i openstack_dashboard/local/local_settings.py
    if [ "$MODE" = "runserver-py35dj20" ]; then
      VENV=manage-py35dj20
      TOXENV=$VENV
    elif [ "$MODE" = "runserver-py35" ]; then
      VENV=manage-py35
      TOXENV=$VENV
    else
      VENV=manage
      TOXENV=$VENV
      # TOXENV=venv
    fi
    tox -e $VENV --notest
    if [ $# -gt 0 ]; then
      .tox/$TOXENV/bin/pip install "$@"
    fi
    PYTHON=.tox/$TOXENV/bin/python
    handle_static_files
    $PYTHON manage.py runserver 0.0.0.0:8000
    ;;
  apache|apache2)
    sed -e 's/^#* *_USE_RUNSERVER = .*/_USE_RUNSERVER = False/' -i openstack_dashboard/local/local_settings.py
    PYTHON=`which python`
    handle_static_files
    sudo service apache2 reload
    ;;
esac
