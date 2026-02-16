# Mac Proxy Utilities

SOCKS5 proxy tunnel from clown to bigfish for accessing blocked sites.

## Setup Files

- `~/bin/socksproxy` - autossh wrapper for SOCKS5 tunnel
- `~/bin/chrome` - Chrome launcher with PAC proxy enabled
- `~/Library/LaunchAgents/com.aaron.socksproxy.plist` - SOCKS tunnel persistence
- `~/Library/LaunchAgents/com.aaron.pacserver.plist` - PAC HTTP server persistence
- `~/Library/WebServer/proxy.pac` - Proxy auto-config domain rules
- `~/.ssh/config` - bigfish SSH keepalive settings

## Management Scripts

- `proxystatus` - Check status of proxy services
- `proxyrestart` - Restart both SOCKS and PAC server
- `proxytest` - Test proxy connectivity
- `proxyadd <domain>` - Add a domain to the proxy list

## Usage

Launch Chrome with proxy enabled:
```bash
chrome https://slack.com
```

Check if everything is running:
```bash
proxystatus
```

Test connectivity:
```bash
proxytest
```

Add a new domain to route through proxy:
```bash
proxyadd reddit.com
```

## Domains Routed Through Proxy

See ~/Library/WebServer/proxy.pac for the current list. Currently includes:
- slack.com and CDN domains
- gmail.com and Google auth/asset domains
- anthropic.com, claude.ai
- openai.com, chatgpt.com

All other traffic goes direct.

## Troubleshooting

View logs:
```bash
tail -f /tmp/socksproxy.err
tail -f /tmp/pacserver.err
```

Restart services:
```bash
proxyrestart
```

Manual service control:
```bash
launchctl unload ~/Library/LaunchAgents/com.aaron.socksproxy.plist
launchctl load ~/Library/LaunchAgents/com.aaron.socksproxy.plist
```
