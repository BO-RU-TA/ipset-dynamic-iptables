#!/bin/bash
# Fragment startu zapory: zestawy muszą istnieć, zanim załadujesz reguły z -m set --match-set.

/fw/ipset/ipset-update.sh static
/fw/ipset/ipset-update.sh dynamic

# ... dalej ładowanie reguł iptables
