# Statyczne i dynamiczne ipsety na zaporze Linux

Skrypty do wpisu „Reguły zapory, które aktualizują się same”.
Listy adresów trzymane w plikach tekstowych są ładowane do zestawów `ipset`,
a reguły `iptables` odwołują się do zestawów po nazwie. Aktualizacja listy
nie wymaga przeładowania zapory, a podmiana zestawu jest atomowa (`ipset swap`).

## Zawartość

```
fw/ipset/
├── ipset-update.sh           # .app → .ip → zestaw: static | dynamic
├── ipset-cleanup.sh          # czyści (--flush) lub usuwa (--destroy) zestawy
├── static/
│   └── payments.app          # adresy i sieci → static_payments
├── dynamic/
│   └── storage.app           # domeny         → dynamic_storage
└── log/
examples/
├── firewall-start.sh         # wywołanie przy starcie zapory
├── crontab                   # odświeżanie list dynamicznych co 5 minut
└── iptables-rules.sh         # przykładowe reguły z -m set --match-set
```

Pliki `*.app` to **przykłady** — zastąp je własnymi listami. Pliki `*.ip` powstają same.

## Wymagania

`bash`, `ipset`, `iptables`, `dig` (pakiet `dnsutils` / `bind9-dnsutils`), uprawnienia roota.

## Instalacja

```bash
cp -r fw /                          # skrypty zakładają katalog /fw/ipset
chmod +x /fw/ipset/*.sh
/fw/ipset/ipset-update.sh static    # utworzy i wypełni zestawy
/fw/ipset/ipset-update.sh dynamic
ipset list -t                       # sprawdź, co powstało
```

Inna lokalizacja: zmień ścieżki `/fw/ipset` w obu skryptach. Argument jest wymagany: bez niego skrypty wypisują `Usage` i kończą się kodem 1.

## Użycie

| Polecenie | Kiedy |
|---|---|
| `ipset-update.sh static` | przy starcie zapory (przed regułami) i ręcznie po zmianie pliku w `static/` |
| `ipset-update.sh dynamic` | przy starcie zapory (przed regułami) i z crona, np. co 5 minut |
| `ipset-cleanup.sh --flush` | czyści zestawy, np. przy zatrzymaniu zapory |
| `ipset-cleanup.sh --destroy` | usuwa zestawy (wymaga wcześniejszego zdjęcia reguł) |

Log: `/fw/ipset/log/DD_MM_RRRR.log`.

## Format plików

Nazwa pliku wyznacza nazwę zestawu: `static/nazwa.app` → `static_nazwa`, `dynamic/nazwa.app` → `dynamic_nazwa`.
Po jednym wpisie w linii; komentarze `#` i `//` oraz puste linie są pomijane.

- **static** — tylko adresy (`192.0.2.10`) i sieci (`198.51.100.0/24`).
- **dynamic** — tylko domeny.

Wszystkie zestawy mają typ `hash:net` (pojedynczy adres = /32).

## Uwagi

- Błędne wpisy trafiają do logu: wpis w niewłaściwej liście jako `skipped`, zły oktet (`300.1.1.1`) jako błąd `ipset`.
- Jeśli któraś domena nie zwróci adresów, zestaw zostaje bez zmian (ostrzeżenie w logu).
- Zestaw jest podmieniany przy każdym przebiegu — po restarcie sam się wypełni.
- Nazwa zestawu ma najwyżej 31 znaków, a skrypt dokleja `_tmp` — nazwa pliku `.app` + prefiks `static_`/`dynamic_` powinny zmieścić się w 27 znakach.
- Migracja ze starszej wersji (zestawy `hash:ip`, w logu `swap failed`): zdejmij reguły, `ipset-cleanup.sh --destroy`,
  `ipset-update.sh static` i `dynamic`, załaduj reguły.
- Usługi z rotującym DNS (np. magazyny w chmurze) lepiej obsłużyć zestawem z `timeout` albo zakresami publikowanymi przez dostawcę — szczegóły we wpisie.
- Tylko IPv4.

## Licencja

MIT — patrz plik [LICENSE](LICENSE).
