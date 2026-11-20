#!/bin/bash

# ipset-cleanup.sh --flush|--destroy
# czyści albo usuwa zestawy, destroy nie usunie zestawu, do którego odwołuje się reguła zapory

# usage
case "$1" in
    --flush)    ACTION=flush                                       ;;
    --destroy)  ACTION=destroy                                     ;;
    *)          echo "Usage: $0 --flush|--destroy" >&2; exit 1     ;;
esac

IPSET="/usr/sbin/ipset"

# przekieruj output do logu
exec >> "/fw/ipset/log/$(date +%d_%m_%Y).log" 2>&1

####

echo "$(date) | cleanup: $ACTION"

for APP in /fw/ipset/static/*.app /fw/ipset/dynamic/*.app; do
    [ -e "$APP" ] || continue

    SET="$(basename "$(dirname "$APP")")_$(basename "$APP" .app)"

    $IPSET "$ACTION" "$SET" && echo "  $SET: $ACTION"
done

###
