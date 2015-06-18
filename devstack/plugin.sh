#!/bin/bash
#
# Copyright 2015 Hewlett-Packard Development Company, L.P.
#
# Licensed under the Apache License, Version 2.0 (the "License"); you may
# not use this file except in compliance with the License. You may obtain
# a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
# License for the specific language governing permissions and limitations
# under the License.

function install_zeromq {
    if is_fedora; then
        install_package zeromq python-zmq
        if [ "$ZEROMQ_MATCHMAKER" == "redis" ]; then
            install_package redis python-redis
        fi
    elif is_ubuntu; then
        install_package libzmq1 python-zmq
        if [ "$ZEROMQ_MATCHMAKER" == "redis" ]; then
            install_package redis-server python-redis
        fi
    elif is_suse; then
        install_package libzmq1 python-pyzmq
        if [ "$ZEROMQ_MATCHMAKER" == "redis" ]; then
            install_package redis python-redis
        fi
    else
        exit_distro_not_supported "zeromq installation"
    fi
    # Necessary directory for socket location.
    sudo mkdir -p /var/run/openstack
    sudo chown $STACK_USER /var/run/openstack
}

function uninstall_zeromq {
    if is_fedora; then
        uninstall_package zeromq python-zmq
        if [ "$ZEROMQ_MATCHMAKER" == "redis" ]; then
            uninstall_package redis python-redis
        fi
    elif is_ubuntu; then
        uninstall_package libzmq1 python-zmq
        if [ "$ZEROMQ_MATCHMAKER" == "redis" ]; then
            uninstall_package redis-server python-redis
        fi
    elif is_suse; then
        uninstall_package libzmq1 python-pyzmq
        if [ "$ZEROMQ_MATCHMAKER" == "redis" ]; then
            uninstall_package redis python-redis
        fi
    else
        exit_distro_not_supported "zeromq installation"
    fi
}

function start_zeromq {
    echo_summary "Starting zeromq receiver"
    run_process zeromq "$OSLO_BIN_DIR/oslo-messaging-zmq-receiver"
}

function iniset_zeromq_backend {
    local package=$1
    local file=$2
    local section=${3:-DEFAULT}

    iniset $file $section rpc_backend "zmq"
    iniset $file $section rpc_zmq_host `hostname`
    if [ "$ZEROMQ_MATCHMAKER" == "redis" ]; then
        iniset $file $section rpc_zmq_matchmaker "redis"
        MATCHMAKER_REDIS_HOST=${MATCHMAKER_REDIS_HOST:-127.0.0.1}
        iniset $file matchmaker_redis host $MATCHMAKER_REDIS_HOST
    else
        die $LINENO "Other matchmaker drivers not supported"
    fi
}

# Note: this is the only tricky part about out of tree rpc plugins,
# you must overwrite the iniset_rpc_backend function so that when
# that's passed around the correct settings files are made.
if is_service_enabled 0mq; then
    function iniset_rpc_backend {
        iniset_zeromq_backend $@
    }
    export -f iniset_rpc_backend
fi

# check for service enabled
if is_service_enabled 0mq; then
    if [[ "$1" == "stack" && "$2" == "pre-install" ]]; then
        # nothing needed here
        :

    elif [[ "$1" == "stack" && "$2" == "install" ]]; then
        # Installs and configures zeromq
        echo_summary "Installing zeromq"
        install_zeromq

    elif [[ "$1" == "stack" && "$2" == "post-config" ]]; then
        # Start zeromq process, this happens before any services start
        start_zeromq

    elif [[ "$1" == "stack" && "$2" == "extra" ]]; then
        :
    fi

    if [[ "$1" == "unstack" ]]; then
        :
    fi

    if [[ "$1" == "clean" ]]; then
        # Remove state and transient data
        # Remember clean.sh first calls unstack.sh
        # no-op
        uninstal_zeromq
    fi
fi
