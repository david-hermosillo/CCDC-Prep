#!/bin/bash
cat > /etc/fail2ban/jail.d/sshd.local <<'EOF'
[sshd]
enabled = true
maxretry = 5
bantime = 3600
EOF
systemctl restart fail2ban
