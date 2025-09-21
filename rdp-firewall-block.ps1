# Only allow RDP from your team subnet (example 10.0.0.0/24). Adjust to your environment.
New-NetFirewallRule -DisplayName "RDP from TeamNet" -Direction Inbound -Protocol TCP -LocalPort 3389 -RemoteAddress 10.0.0.0/24 -Action Allow
New-NetFirewallRule -DisplayName "RDP Block All Others" -Direction Inbound -Protocol TCP -LocalPort 3389 -RemoteAddress Any -Action Block -Profile Any