# logtop

> **`top` for log files.** Live-tail any log and group lines by IP, HTTP status, log level, or custom regex. Updates in place. No installs.

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Bash](https://img.shields.io/badge/shell-bash-1f425f.svg)](#)
[![No deps](https://img.shields.io/badge/deps-tail%20%2B%20awk-brightgreen.svg)](#)
[![Stars](https://img.shields.io/github/stars/fafsfafaf/logtop?style=social)](https://github.com/fafsfafaf/logtop/stargazers)

```bash
bash logtop.sh /var/log/nginx/access.log
bash logtop.sh /var/log/nginx/access.log --by status
bash logtop.sh /var/log/auth.log         --by 'Failed password.*from ([0-9.]+)'
```

## Demo

Recorded with [asciinema](https://asciinema.org/). View it locally:

```bash
# install asciinema if needed: pip install asciinema
asciinema play demo.cast
```

Or upload to asciinema.org for an embeddable badge:

```bash
asciinema auth      # one-time, opens browser
asciinema upload demo.cast
```

## Why

When something goes wrong in production, you `tail -f` a log and your eyes glaze over. You really want to know **"which IP is hammering us?"** or **"how many 5xx in the last minute?"** — that's `logtop`.

It's `top`, but for log patterns: live, sorted, updating in place, with bars.

## Modes

| Mode | What it groups by |
|------|-------------------|
| `--by ip` (default) | First IPv4 in each line — great for nginx/apache |
| `--by status` | 3-digit HTTP status — colored 2xx green, 4xx yellow, 5xx red |
| `--by level` | DEBUG/INFO/WARN/ERROR/CRITICAL/FATAL — colored by severity |
| `--by '<regex>'` | Any custom regex |

## Output

```
logtop v1.0.0 · /var/log/nginx/access.log · HTTP status · 18342 lines · 12s elapsed

  VALUE                                COUNT     PCT
  ──────────────────────────────────────────────────────────
  200                                  14201    77.4%  █████████████████████████
  304                                   2891    15.7%  █████
  404                                    811     4.4%  █
  500                                    312     1.7%
  301                                    127     0.7%
```

## Use cases

```bash
# See who's hammering nginx right now
bash logtop.sh /var/log/nginx/access.log

# Real-time HTTP status breakdown during an incident
bash logtop.sh /var/log/nginx/access.log --by status

# SSH brute-force attempts (extract source IPs from auth.log)
bash logtop.sh /var/log/auth.log --by 'Failed password.*from ([0-9.]+)'

# Track which microservice is loudest in app logs
bash logtop.sh /var/log/app.log --by '\[([a-z-]+)\]'

# App log levels at a glance
bash logtop.sh /var/log/app.log --by level
```

## Options

| Flag | Default | Purpose |
|------|---------|---------|
| `--by <mode>` | `ip` | grouping (`ip`, `status`, `level`, or custom regex) |
| `--top N`   | 20 | how many rows to show |
| `--interval N` | 1 | refresh interval in seconds |

## Dependencies

`tail`, `awk`, `grep` — every Linux box already has them.

## License

MIT
