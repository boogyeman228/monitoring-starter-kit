# ProbeFlapping

**Severity:** warning - **Fires when:** a probe changed state (up/down) 4 or more times within 15 minutes, for at least 5 minutes.

## Symptoms
- Telegram alert `[FIRING] ProbeFlapping` for an `instance`.
- Grafana "Status" panel flickers between UP and DOWN; users report "sometimes it works".

## First 5 checks
1. **Pattern:** in Grafana Explore graph `probe_success{instance="..."}` over 6-24h. Regular intervals (every 5/10/60 min) point to a cron job, backup, log rotation or restart loop.
2. **Failure reason:** compare `probe_http_status_code` and `probe_http_duration_seconds` during the failures - timeouts (slow backend) vs 5xx (app errors) vs 0 (connection refused).
3. **Multiple backends?** A load balancer with one unhealthy node returns errors for a fraction of requests. Check each backend directly.
4. **Resources:** the service restarting due to out-of-memory (`dmesg | grep -i oom`, `docker ps` restart counts, `journalctl -u <service>`).
5. **Network path:** packet loss between the monitoring host and the target - `mtr your-site.com` for a few minutes; compare with the ICMP probe if you have one.

## Escalation
- Flapping that correlates with real user impact, or lasts more than 1 hour: escalate to the service owner with the graph from step 1.

## Resolution notes
- This alert is suppressed while `EndpointDown` is firing for the same instance, and clears when the probe is stable for 15 minutes.
- Intermittent failures are often an early warning of a bigger outage; open a ticket even if it self-heals.
