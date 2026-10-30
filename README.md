# Monitoring Starter Kit

[English](README.md) | [Русский](README.ru.md)

Website and server uptime monitoring with **Telegram alerts** in one `docker compose up`. Built on Prometheus, Blackbox Exporter, Alertmanager and Grafana - small enough to run on a $5 VPS.

- Probes HTTP(S) endpoints (and hosts via ICMP ping) every 30 seconds
- Alerts to Telegram: endpoint down, slow response, SSL certificate expiring, flapping endpoint
- Each alert links to a short runbook (`runbooks/`) with the first checks to make
- Ready-made Grafana dashboard: up/down status, response time, SSL days left, uptime 24h / 7d
- Only Grafana is exposed; everything else stays inside the Docker network
- Add a site with one command, no restart needed

<!-- TODO: add a real screenshot of the "Website Uptime & SSL" dashboard as docs/dashboard.png, then add: ![Dashboard screenshot](docs/dashboard.png) -->

## Architecture

```
targets/http.yml --> Prometheus --probe--> Blackbox Exporter --> your sites / hosts
                         |  \--alerts.yml
                         v
                   Alertmanager --> Telegram
                         ^
                   Grafana (dashboard, port 3000)
```

## Quickstart (5 minutes)

Requirements: a Linux VPS (or any machine) with Docker Engine and the Compose plugin.

```bash
git clone https://github.com/boogyeman228/monitoring-starter-kit.git
cd monitoring-starter-kit

cp .env.example .env
# edit .env: Telegram token + chat id (see below) and a strong Grafana password

# optional, only if you forked: point the alert runbook links at your fork
# sed -i 's/boogyeman228/<your-github-user>/' prometheus/alerts.yml

./scripts/add-target.sh https://your-site.com   # then delete the example.com entries in targets/http.yml
docker compose up -d
```

Open `http://<server-ip>:3000`, log in with the credentials from `.env`, and open the **Website Uptime & SSL** dashboard.

To test alerting, add a URL that cannot work, e.g. `./scripts/add-target.sh https://does-not-exist.invalid`. After about 3 minutes you should get an `EndpointDown` message in Telegram. Remove the target afterwards by deleting its line from `targets/http.yml`.

## Create a Telegram bot and get the chat ID

1. In Telegram, open [@BotFather](https://t.me/BotFather), send `/newbot`, and follow the prompts. Copy the **token** (`123456789:AA...`) into `TELEGRAM_BOT_TOKEN`.
2. Start a chat with your new bot and send it any message. For a group: add the bot to the group, then send a message in the group.
3. Open this URL in a browser (replace `<TOKEN>`): `https://api.telegram.org/bot<TOKEN>/getUpdates`
4. Find `"chat":{"id": ...}` in the JSON. That number is your `TELEGRAM_CHAT_ID` (groups are negative, e.g. `-1001234567890`). If the result is empty, send another message and reload.
5. Optional test: `curl "https://api.telegram.org/bot<TOKEN>/sendMessage?chat_id=<CHAT_ID>&text=hello"`

Keep the token secret: anyone with it can post as your bot. Anyone in the chat can read your alerts.

## Adding targets

HTTP(S) sites - run the helper, or edit `targets/http.yml` by hand (one list item per site):

```bash
./scripts/add-target.sh https://shop.example.com        # Linux / macOS / Git Bash
.\scripts\add-target.ps1 https://shop.example.com        # Windows PowerShell
```

```yaml
- targets: ['https://shop.example.com']
```

Prometheus re-reads the file every minute; no restart is needed. Ping targets go in `targets/icmp.yml`.

After changing `prometheus/alerts.yml` or `prometheus/prometheus.yml`, reload with `docker compose kill -s SIGHUP prometheus`.

## Alerts

| Alert | Severity | Condition |
|---|---|---|
| `EndpointDown` | critical | probe failing for 2 min (or the probe cannot run at all) |
| `SlowResponse` | warning | response time > 2 s for 5 min |
| `SSLExpiringSoon` | warning | certificate expires in < 14 days |
| `ProbeFlapping` | warning | 4+ up/down changes in 15 min |

`EndpointDown` suppresses `SlowResponse` and `ProbeFlapping` for the same endpoint. Critical alerts repeat hourly, warnings every 4 hours. Runbooks: [`runbooks/`](runbooks/).

## Validate the configuration (optional, needs Docker)

Run from the repository root. These commands only read your files; they do not start the stack.

```bash
# Prometheus config + alert rules
docker run --rm -v "$PWD/prometheus:/etc/prometheus:ro" -v "$PWD/targets:/targets:ro" \
  --entrypoint promtool prom/prometheus:v3.5.0 check config /etc/prometheus/prometheus.yml

# Alertmanager config (placeholders are replaced with dummy values for the check)
docker run --rm -v "$PWD/alertmanager:/etc/alertmanager:ro" --entrypoint /bin/sh prom/alertmanager:v0.28.1 \
  -c "sed -e 's|__TELEGRAM_BOT_TOKEN__|123:dummy|' -e 's|__TELEGRAM_CHAT_ID__|1|' /etc/alertmanager/alertmanager.yml > /tmp/am.yml && amtool check-config /tmp/am.yml"

# Blackbox config
docker run --rm -v "$PWD/blackbox:/etc/blackbox:ro" --entrypoint /bin/blackbox_exporter \
  prom/blackbox-exporter:v0.27.0 --config.check --config.file=/etc/blackbox/blackbox.yml

# Compose file (needs a .env, see Quickstart)
docker compose config --quiet
```

On Windows PowerShell replace `"$PWD/..."` with `"${PWD}/..."` and the trailing `\` line continuations with a backtick or put each command on one line.

## Security notes

- **Change the Grafana admin password** in `.env` before the first start. Grafana only reads it when it creates its database; to change it later use the UI or `docker compose exec grafana grafana cli admin reset-admin-password <new>`.
- **Firewall:** allow only SSH and what you need. Example with ufw: `ufw allow 22/tcp && ufw allow 3000/tcp && ufw enable`. Note that Docker publishes ports by modifying iptables directly, so ufw rules may not restrict a published port. The reliable fix is to bind it to localhost (`GRAFANA_BIND=127.0.0.1`) and put a reverse proxy with HTTPS (Caddy, nginx) in front, or restrict by source IP at the cloud-provider firewall.
- Prometheus, Alertmanager and Blackbox have **no published ports** and no authentication - keep it that way.
- Never commit `.env` (it is in `.gitignore`). The Telegram token is rendered into a tmpfs copy of the Alertmanager config at start-up and is not stored on disk. It is visible to anyone who can run `docker inspect` on the host.
- Blackbox probes make outbound requests to whatever is in `targets/`. Only monitor URLs you are allowed to test.
- Image versions are pinned. Check for updates periodically and re-run the validation above.

## Cost estimate

| Item | Approx. cost |
|---|---|
| VPS, 1 vCPU / 1 GB RAM (Hetzner, DigitalOcean, etc.) | $4-6 / month |
| Domain for Grafana + HTTPS (optional) | ~$10-15 / year |
| Telegram bot | free |

The containers are limited to about 700 MB RAM combined (see `mem_limit` in `docker-compose.yml`); typical use for a few dozen targets is well below that. Adding a 1-2 GB swap file on a 1 GB VPS is a sensible safety margin. Data is kept for 30 days (max 2 GB).

## Limitations

- Single instance: if the VPS itself goes down, no alert is sent. Use a second location or an external heartbeat service for a "monitor the monitor" check.
- Probes run from one location, so a network problem near the VPS can look like an outage.

## Need this set up for you?

I set up and tune monitoring for small businesses: server, targets, Telegram/e-mail alerts, dashboards and a handover document.

- Contact: [LinkedIn](https://www.linkedin.com/in/bogdansalvador)

## License

MIT - see [LICENSE](LICENSE).
