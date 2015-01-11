ansible-playbook for me
=======================

This repository maintains my private ansible playbooks.
At now it is used to setup OpenStack devstack environment on Ubuntu/Debian environments.

    ansible-playbook myenv.yml --ask-vault-pass -e host=dev09
    ansible-playbook myenv.yml --skip-tags sensible -e host=dev09

Playbook for I18N Horizon check site
------------------------------------

    ansible-playbook --ask-vault-pass -e host=dev15 i18n-devstack.yml -vv -e branch=stable/juno
