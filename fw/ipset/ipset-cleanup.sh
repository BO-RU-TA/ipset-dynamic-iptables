#!/bin/bash

# ipset-cleanup.sh --flush|--destroy
# flushes or destroys the sets; destroy fails for a set still referenced by a firewall rule

# usage
case "$1" in
    --flush)    ACTION=flush                                       ;;
    --destroy)  ACTION=destroy                                     ;;
    *)          echo "Usage: $0 --flush|--destroy" >&2; exit 1     ;;
esac

IPSET="/usr/sbin/ipset"

# send all output, including errors, to the daily log
exec >> "/fw/ipset/log/$(date +%d_%m_%Y).log" 2>&1

####

echo "$(date) | cleanup: $ACTION"

for APP in /fw/ipset/static/*.app /fw/ipset/dynamic/*.app; do
    [ -e "$APP" ] || continue

    SET="$(basename "$(dirname "$APP")")_$(basename "$APP" .app)"

    $IPSET "$ACTION" "$SET" && echo "  $SET: $ACTION"
done

###
