# EndpointDown

**Severity:** critical - **Fires when:** a probe (HTTP or ICMP) has failed for 2 minutes, or the probe itself could not run.

## Symptoms
- Telegram alert `[FIRING] EndpointDown` for an `instance` (URL or IP).
- Grafana "Status" panel shows DOWN; response time graph has a gap.

## First 5 checks
1. **Is it really down?** Open the URL from your phone (mobile data) and from another network. Rule out a local network issue.
2. **What does the probe say?** Prometheus is not published, so use the Grafana "Explore" tab, or run
   `docker compose exec prometheus wget -qO- 'http://blackbox:9115/probe?module=http_2xx&target=https://your-site.com&debug=true'`
   and read the log: DNS failure, connection refused, TLS error, or non-2xx status?
3. **DNS:** `nslookup your-site.com` - does it resolve to the expected IP?
4. **Server/service:** is the host up (`ping`, provider panel) and is the web server running (`systemctl status nginx`, `docker ps`)? Check disk full / out of memory.
5. **Recent changes:** deploys, certificate renewals, firewall or DNS edits in the last hour.

If the alert says the blackbox probe was "not scraped" (`up == 0`), the problem is in this stack: `docker compose ps` and `docker compose logs blackbox`.

## Escalation
- Not resolved in 15 minutes, or customer-facing: escalate to the service owner / hosting provider. Include the instance, time the alert fired, and the probe debug output from step 2.

## Resolution notes
- The alert resolves automatically after the first successful probe; a `[RESOLVED]` message is sent.
- Record the root cause and fix in your incident log. If it was a false alarm (e.g. the site blocks the probe's User-Agent), adjust `blackbox/blackbox.yml`.
