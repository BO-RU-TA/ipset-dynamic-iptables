#!/bin/bash
# Sample rules referencing the sets (fragment of a firewall script).
# Chains _fwd_v0020_i/_o, interface eth2 and network 10.0.20.0/24 are examples.

IPTABLES="/usr/sbin/iptables"

# VLAN 20: access to the payment gateway from the whole subnet

$IPTABLES -I _fwd_v0020_i -o eth2 -p tcp -m set --match-set static_payments dst -s 10.0.20.0/24 -j ACCEPT
$IPTABLES -I _fwd_v0020_o -i eth2 -p tcp -m set --match-set static_payments src -d 10.0.20.0/24 -j ACCEPT

# VLAN 20: file storage for a single server only

$IPTABLES -I _fwd_v0020_i -o eth2 -m set --match-set dynamic_storage dst -s 10.0.20.16 -j ACCEPT
$IPTABLES -I _fwd_v0020_o -i eth2 -m set --match-set dynamic_storage src -d 10.0.20.16 -j ACCEPT
