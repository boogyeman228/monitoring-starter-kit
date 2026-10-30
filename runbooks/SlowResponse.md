# SlowResponse

**Severity:** warning - **Fires when:** a successful HTTP probe takes longer than 2 seconds for 5 minutes.

## Symptoms
- Telegram alert `[FIRING] SlowResponse` for an `instance`.
- Grafana "Response time" panel is above the 2s line; users report a sluggish site.

## First 5 checks
1. **Where is the time spent?** In Grafana Explore query `probe_http_duration_seconds{instance="https://your-site.com"}` - it is split by phase (`resolve`, `connect`, `tls`, `processing`, `transfer`). High `processing` = slow application; high `connect`/`tls` = network or TLS issue; high `resolve` = DNS.
2. **Server load:** `uptime`, `top`/`htop`, `free -m`. CPU saturated or swapping?
3. **Backend dependencies:** slow database queries, external API calls, full disk, exhausted connection pool.
4. **Traffic:** unusual spike or bot crawl in the web server access log.
5. **Recent changes:** new deploy, plugin, cron job or backup running at the same time.

## Escalation
- Persisting more than 30 minutes, or climbing toward timeouts (10s) which will turn into `EndpointDown`: escalate to the application owner / hosting provider with the phase breakdown from step 1.

## Resolution notes
- Resolves automatically once response time stays under 2s.
- If 2s is too strict or too loose for this site, change the threshold in `prometheus/alerts.yml` and reload: `docker compose kill -s SIGHUP prometheus`.
