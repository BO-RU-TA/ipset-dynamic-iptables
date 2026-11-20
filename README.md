# ipset-dynamic-iptables

Static and dynamic `ipset` allow-lists for a Linux `iptables` firewall.

Address lists live in plain text files and are loaded into `ipset` sets; `iptables` rules refer to the sets by name.
Updating a list never requires reloading the firewall, and every set is replaced atomically (`ipset swap`),
so rules never see an empty or half-filled set.

- **static** lists — IP addresses and networks you maintain by hand
- **dynamic** lists — domain names, resolved periodically (e.g. from cron)

## Contents

```
fw/ipset/
├── ipset-update.sh           # .app → .ip → set: static | dynamic
├── ipset-cleanup.sh          # flush (--flush) or destroy (--destroy) the sets
├── static/
│   └── payments.app          # addresses and networks → set static_payments
├── dynamic/
│   └── storage.app           # domain names           → set dynamic_storage
└── log/
examples/
├── firewall-start.sh         # call at firewall start
├── crontab                   # refresh dynamic lists every 5 minutes
└── iptables-rules.sh         # sample rules with -m set --match-set
```

The `*.app` files are **examples** — replace them with your own lists. The `*.ip` files are generated.

## Requirements

`bash`, `ipset`, `iptables`, `dig` (package `dnsutils` / `bind9-dnsutils`), root privileges.

## Installation

```bash
cp -r fw /                          # the scripts expect /fw/ipset
chmod +x /fw/ipset/*.sh
/fw/ipset/ipset-update.sh static    # creates and fills the sets
/fw/ipset/ipset-update.sh dynamic
ipset list -t                       # check what was created
```

Different location: change the `/fw/ipset` paths in both scripts.
An argument is required — without it the scripts print `Usage` and exit with code 1.

## Usage

| Command | When |
|---|---|
| `ipset-update.sh static` | at firewall start (before the rules) and manually after editing a file in `static/` |
| `ipset-update.sh dynamic` | at firewall start (before the rules) and from cron, e.g. every 5 minutes |
| `ipset-cleanup.sh --flush` | empties the sets, e.g. when stopping the firewall |
| `ipset-cleanup.sh --destroy` | removes the sets (remove the rules that reference them first) |

Log: `/fw/ipset/log/DD_MM_YYYY.log`

```
Wed Jan  1 00:20:01 CET 2025 | dynamic
  dynamic_storage: 14 entries < 198.51.100.17 > 198.51.100.42 …
Wed Jan  1 00:30:01 CET 2025 | dynamic
  dynamic_storage: 14 entries (no change)
```

`<` = address removed, `>` = address added.

## File format

The file name defines the set name: `static/name.app` → `static_name`, `dynamic/name.app` → `dynamic_name`.
One entry per line; `#` and `//` comments and empty lines are ignored.

- **static** — only addresses (`192.0.2.10`) and networks (`198.51.100.0/24`)
- **dynamic** — only domain names

All sets use the `hash:net` type (a single address is stored as /32), so `swap` always gets compatible sets.

## How `ipset-update.sh` works

For every `*.app` file in the chosen directory it:

1. creates the set if it does not exist (even when DNS is down — firewall rules must be able to find it),
2. builds a new `.ip` file: copies addresses/networks (static) or resolves domains with `dig` (dynamic);
   entries that do not belong in that kind of list are skipped and logged,
3. if any domain returned no A records or the list is empty — **leaves the set unchanged**,
4. logs the difference between the old and the new `.ip` file,
5. loads the `.ip` file into a temporary set and swaps it with the live one (`ipset swap`).

The set is swapped on every run, even when nothing changed — cheap for small lists, and after a reboot
the sets refill themselves even if the `.ip` files are unchanged.

## Notes

- Invalid entries only show up in the log: an entry in the wrong kind of list as `skipped`,
  a bad octet (`300.1.1.1`) as an `ipset` error.
- A set name is limited to 31 characters and the script appends `_tmp` — keep the `static_`/`dynamic_` prefix
  plus the `.app` file name within 27 characters.
- Migrating from an older version (sets of type `hash:ip`, `swap failed` in the log): remove the rules,
  run `ipset-cleanup.sh --destroy`, then `ipset-update.sh static` and `dynamic`, and load the rules again.
- Cloud and CDN endpoints often rotate addresses on every DNS query. A set with entry `timeout`
  (each resolved address added with `ipset add … timeout 3600 -exist`) keeps the addresses seen in the last hour.
  Avoid allowing whole provider ranges instead: that opens the firewall to every customer of that provider
  (any bucket, any site behind the CDN), not just your service.
- Shared cloud/CDN addresses serve many tenants at once, so IP filtering narrows the traffic but does not
  identify the service. Where that matters, filter by name (proxy with SNI/Host checks) or use a private endpoint.
- IPv4 only.

## License

MIT — see [LICENSE](LICENSE).
