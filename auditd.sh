auditctl -w /etc/passwd -p wa -k passwd_changes
auditctl -w /etc/shadow -p wa -k shadow_changes
auditctl -w /etc/ssh/sshd_config -p wa -k ssh_config_changes
Logs go to /var/log/audit/audit.log.
