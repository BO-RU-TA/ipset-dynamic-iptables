#!/bin/bash
# ipset-update.sh static|dynamic
# tworzy i aktualizuje zestawy: static - adresy i sieci, dynamic - domeny

case "$1" in
    static|dynamic) MODE="$1" ;;
    *)              echo "Usage: $0 static|dynamic" >&2; exit 1 ;;
esac

DIR="/fw/ipset/$MODE"

IPSET="/usr/sbin/ipset"
IP4RE='^[0-9]{1,3}(\.[0-9]{1,3}){3}(/[0-9]{1,2})?$'

# przekieruj output do logu
exec >> "/fw/ipset/log/$(date +%d_%m_%Y).log" 2>&1

echo "$(date) | $MODE"

for APP in "$DIR"/*.app; do
    [ -e "$APP" ] || continue

    SET="${MODE}_$(basename "$APP" .app)"
    IPF="${APP%.app}.ip"

    # zestaw musi istnieć, zanim zapora załaduje reguły
    $IPSET create "$SET" hash:net -exist

    # .app -> .ip.new: static przepisuje adresy, dynamic rozwiązuje domeny
    OK=1
    while read -r E; do
        case "$MODE" in
            static)  [[ $E =~ $IP4RE ]] && { echo "$E"; continue; } ;;
            dynamic) [[ $E =~ [a-zA-Z] ]] && {
                         dig +short +time=1 +tries=2 A "$E" | grep -E "$IP4RE" \
                             || { echo "  $SET: $E - no A records" >&2; OK=0; }
                         continue; } ;;
        esac
        echo "  $SET: skipped '$E' - not valid in $MODE list" >&2
    done < <(sed -E 's@(#|//).*@@; s/[[:blank:]]//g; /^$/d' "$APP") > "$IPF.new"
    sort -u -o "$IPF.new" "$IPF.new"

    # niepełna albo pusta lista - zestaw bez zmian
    if [ $OK = 0 ] || [ ! -s "$IPF.new" ]; then
        echo "  $SET: unchanged"
        rm -f "$IPF.new"
        continue
    fi

    # różnice względem poprzedniego .ip - tylko do logu
    touch "$IPF"
    CHANGES="$(diff "$IPF" "$IPF.new" | grep '^[<>]' | tr '\n' ' ')"
    mv "$IPF.new" "$IPF"

    # zestaw tymczasowy i atomowa podmiana
    $IPSET create "${SET}_tmp" hash:net -exist
    $IPSET flush "${SET}_tmp"
    while read -r E; do
        $IPSET add "${SET}_tmp" "$E" -exist
    done < "$IPF"

    if $IPSET swap "${SET}_tmp" "$SET"; then
        echo "  $SET: $(wc -l < "$IPF") entries ${CHANGES:-(no change)}"
    else
        echo "  $SET: swap failed - set left unchanged"
    fi
    $IPSET destroy "${SET}_tmp"
done
