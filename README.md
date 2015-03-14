ansible-playbook for me
=======================

This repository maintains my private ansible playbooks.
At now it is used to setup OpenStack devstack environment on Ubuntu/Debian environments.

    ansible-playbook all.yml -e host=dev09

myenv playbook
--------------

Prepare secrets.yml in the top directory before running myenv.yml.
The sample file is found at roles/myenv/vars/secrets_dummy.yml

Playbook for I18N Horizon check site
------------------------------------

Moved to https://github.com/amotoki/ansible-i18n-devstack/
