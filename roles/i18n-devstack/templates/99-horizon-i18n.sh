# ironic.sh - Devstack extras script to install ironic

if is_service_enabled horizon; then
    if [[ "$1" == "source" ]]; then
        :
    elif [[ "$1" == "stack" && "$2" == "pre-install" ]]; then
        if [ -d $DEST/horizon ]; then
            cd $DEST/horizon
            rm -rf horizon/locale
            rm -rf openstack_dashboard/locale
            git checkout -- .
        fi
    elif [[ "$1" == "stack" && "$2" == "install" ]]; then
        :
    elif [[ "$1" == "stack" && "$2" == "post-config" ]]; then
        :
    elif [[ "$1" == "stack" && "$2" == "extra" ]]; then
        local_settings=$HORIZON_DIR/openstack_dashboard/local/local_settings.py
        _horizon_config_set $local_settings OPENSTACK_API_VERSIONS identity 3
        _horizon_config_set $local_settings OPENSTACK_API_VERSIONS volume 2
        _horizon_config_set $local_settings OPENSTACK_CINDER_FEATURES enable_backup True

        $HOME/horizon-i18n-tools/import-trans.sh -r {{ branch|basename }}

        restart_apache_server
        :
    fi

    if [[ "$1" == "unstack" ]]; then
        :
    fi

    if [[ "$1" == "clean" ]]; then
        :
    fi
fi
