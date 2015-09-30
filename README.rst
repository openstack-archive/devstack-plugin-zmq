======================
 Enabling in Devstack
======================

1. Download DevStack

2. Add this repo as an external repository::

     cat > local.conf
     [[local|localrc]]
     enable_plugin zmq https://github.com/stackforge/devstack-plugin-zmq

3. run ``stack.sh``
