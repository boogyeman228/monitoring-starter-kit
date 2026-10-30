# SSLExpiringSoon

**Severity:** warning - **Fires when:** the TLS certificate served by an HTTPS endpoint expires in less than 14 days.

## Symptoms
- Telegram alert `[FIRING] SSLExpiringSoon` showing the days remaining.
- Grafana "SSL days left" bar is orange/red.

## First 5 checks
1. **Confirm the expiry date:** `echo | openssl s_client -connect your-site.com:443 -servername your-site.com 2>/dev/null | openssl x509 -noout -dates -issuer`
2. **Is auto-renewal supposed to be in place?** Let's Encrypt via certbot/Caddy/Traefik/hosting panel? If yes, renewal is broken - find out why.
3. **Renewal logs:** `certbot renew --dry-run`, `journalctl -u certbot`, or the proxy's logs. Typical causes: port 80 blocked, DNS changed, rate limit, expired API token for DNS-01.
4. **Is the renewed cert actually being served?** A renewed certificate on disk is useless until the web server reloads (`nginx -s reload`). Also check CDN/load balancer certificates.
5. **Other hostnames:** do other domains or subdomains share the same renewal setup and risk the same failure?

## Escalation
- Under 7 days left and you cannot renew: escalate to whoever owns the domain/DNS or hosting account today. Expiry causes full browser warnings for all visitors.

## Resolution notes
- The alert clears after the renewed certificate is served and the next probe sees the new expiry date.
- Fix the root cause of the failed auto-renewal, not only this one certificate.
