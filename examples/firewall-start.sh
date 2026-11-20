#!/bin/bash
# Firewall start fragment: the sets must exist before loading rules that use -m set --match-set.

/fw/ipset/ipset-update.sh static
/fw/ipset/ipset-update.sh dynamic

# ... then load the iptables rules
