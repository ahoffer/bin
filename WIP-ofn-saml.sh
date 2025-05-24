#!/usr/bin/env bash
#
# ofn-saml.sh — run openfortivpn with SAML and auto-open browser as your user.

# === Configuration ===
VPN_HOST="east1.octo.us:10443"
LOCAL_USER="aaron"
# ======================

# Kick off openfortivpn under sudo, capturing its output
sudo openfortivpn "$VPN_HOST" --saml-login 2>&1 | {
  while IFS= read -r line; do
    # Show the log line
    echo "$line"
    # When we see the Authenticate URL, launch it in your browser
    if [[ "$line" =~ Authenticate\ at\ \'(.*)\' ]]; then
      URL="${BASH_REMATCH[1]}"
      echo "→ Opening browser for SAML login: $URL"
      # Launch xdg-open as your user, with your env
      sudo -u "$LOCAL_USER" \
         DISPLAY="$DISPLAY" \
         XAUTHORITY="$XAUTHORITY" \
         DBUS_SESSION_BUS_ADDRESS="$DBUS_SESSION_BUS_ADDRESS" \
         xdg-open "$URL" >/dev/null 2>&1 &
    fi
  done
}
