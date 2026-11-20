#!/bin/bash
# Przykładowe reguły odwołujące się do zestawów (fragment skryptu zapory).
# Łańcuchy _fwd_v0020_i/_o, interfejs eth2 i sieć 10.0.20.0/24 to przykłady.

IPTABLES="/usr/sbin/iptables"

# VLAN 20: dostęp do bramki płatności z całej podsieci

$IPTABLES -I _fwd_v0020_i -o eth2 -p tcp -m set --match-set static_payments dst -s 10.0.20.0/24 -j ACCEPT
$IPTABLES -I _fwd_v0020_o -i eth2 -p tcp -m set --match-set static_payments src -d 10.0.20.0/24 -j ACCEPT

# VLAN 20: magazyn plików tylko dla jednego serwera

$IPTABLES -I _fwd_v0020_i -o eth2 -m set --match-set dynamic_storage dst -s 10.0.20.16 -j ACCEPT
$IPTABLES -I _fwd_v0020_o -i eth2 -m set --match-set dynamic_storage src -d 10.0.20.16 -j ACCEPT
