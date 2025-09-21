#!/bin/bash
ufw default deny incoming
ufw default allow outgoing
ufw allow 22/tcp
ufw allow 80/tcp
ufw allow 443/tcp
ufw allow 53/udp
# FTP and SMB if you must:
ufw allow 21/tcp
ufw allow 445/tcp
ufw enable
ufw status verbose
