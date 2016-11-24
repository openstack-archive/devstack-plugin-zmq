========================
Team and repository tags
========================

.. image:: http://governance.openstack.org/badges/devstack-plugin-zmq.svg
    :target: http://governance.openstack.org/reference/tags/index.html

.. Change things from this point on

======================
 Enabling in Devstack
======================

1. Download DevStack

2. Add this repo as an external repository::

     cat > local.conf
     [[local|localrc]]
     enable_plugin zmq https://git.openstack.org/openstack/devstack-plugin-zmq

3. run ``stack.sh``
