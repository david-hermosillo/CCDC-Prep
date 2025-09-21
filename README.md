# CCDC-Prep
•	Create an emergency admin account (so if current admin gets locked out you have a fallback).
useradd -m -s /bin/bash secadmin
passwd secadmin   # set strong password
usermod -aG wheel secadmin   # CentOS (wheel), or:
usermod -aG sudo secadmin    # Debian
Windows (PowerShell as Administrator):
$pw = Read-Host -AsSecureString "Enter password for secadmin"
New-LocalUser -Name secadmin -Password $pw -FullName "Competition Admin"
Add-LocalGroupMember -Group "Administrators" -Member "secadmin"
B. Windows Server 2016 & Windows Server 2019
(Do both Windows hosts using the same steps; adapt for roles installed.)
1) Patching & baseline
•	Open PowerShell (Admin):
•	Install-Module PSWindowsUpdate -Force -AllowClobber
•	Import-Module PSWindowsUpdate
•	Get-WindowsUpdate -AcceptAll -Install -AutoReboot
If PSWindowsUpdate is not allowed, use Windows Update GUI. Reboot if required.
2) Create/verify emergency admin (if not already done)
(see shared prep)
3) Lock RDP and remote access
•	Enforce NLA (Network Level Authentication) and restrict RDP through firewall:
•	# Require NLA
•	Set-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp' -Name 'UserAuthentication' -Value 1
•	
•	# Only allow RDP from your team subnet (example 10.0.0.0/24). Adjust to your environment.
•	New-NetFirewallRule -DisplayName "RDP from TeamNet" -Direction Inbound -Protocol TCP -LocalPort 3389 -RemoteAddress 10.0.0.0/24 -Action Allow
•	# Block RDP from other addresses
•	New-NetFirewallRule -DisplayName "RDP Block All Others" -Direction Inbound -Protocol TCP -LocalPort 3389 -RemoteAddress Any -Action Block -Profile Any
•	Disable RDP if not required on that host:
•	Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server" -Name "fDenyTSConnections" -Value 1
4) Disable SMBv1 and harden SMB
# Disable SMBv1
Set-SmbServerConfiguration -EnableSMB1Protocol $false -Force
# Ensure SMB signing optional/required (if needed)
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters" -Name "RequireSecuritySignature" -Value 1 -Type DWord
Restart-Service -Name LanmanServer
5) IIS (HTTP/HTTPS) hardening quick checklist
•	Ensure only TLS 1.2/1.3 enabled, disable weak ciphers (use IIS Crypto tool if available). Quick registry edits are possible, but be careful.
•	Disable directory browsing via IIS Manager → Sites → select site → Features → Directory Browsing → Disable.
•	Ensure site runs under application pool with least privilege.
•	If you have certs, bind HTTPS and force redirect 80 → 443.
6) DNS (if DNS role installed)
•	Disable recursion unless required. In DNS Manager: Right-click server → Properties → Advanced → uncheck "Enable recursion".
•	Restrict zone transfers: Right-click zone → Properties → Zone Transfers → Only to servers listed on the Name Servers tab.
7) Logging & quick monitors
•	Start watching event logs:
•	# show last 50 Security events
•	Get-WinEvent -LogName Security -MaxEvents 50 | Format-Table TimeCreated,Id,LevelDisplayName,Message -AutoSize
•	# live tail (PowerShell 7 has Get-EventLog -Wait, otherwise loop)
•	Enable auditing for logon failures if not already present (GPOs or Local Security Policy).
8) Quick verification commands
Test-NetConnection -ComputerName localhost -Port 80
Test-NetConnection -ComputerName localhost -Port 443
Test-NetConnection -ComputerName localhost -Port 53   # DNS
9) Quick response actions (if attack found)
•	Block IP immediately:
•	New-NetFirewallRule -DisplayName "Block malicious IP x.x.x.x" -Direction Inbound -RemoteAddress x.x.x.x -Action Block
•	Reset admin passwords:
•	Set-LocalUser -Name "Administrator" -Password (Read-Host -AsSecureString "New Admin Password")
C. CentOS 7 (RHEL-like) — commands & edits
1) Update packages
yum -y update
(reboot if kernel updated)
2) Create emergency admin (see shared prep)
3) Firewall: use firewalld
•	Allow only required services (HTTP, HTTPS, SSH, DNS, FTP, Samba):
# open common services
firewall-cmd --permanent --add-service=http
firewall-cmd --permanent --add-service=https
firewall-cmd --permanent --add-service=ssh
firewall-cmd --permanent --add-service=dns
# FTP may require additional ports for passive mode; open if you're running ftp server
firewall-cmd --permanent --add-service=ftp
# Samba (SMB)
firewall-cmd --permanent --add-service=samba
firewall-cmd --reload
•	To restrict SSH to team subnet:
firewall-cmd --permanent --add-rich-rule='rule family="ipv4" source address="10.0.0.0/24" service name="ssh" accept'
firewall-cmd --permanent --add-rich-rule='rule family="ipv4" service name="ssh" drop'
firewall-cmd --reload
4) SSH hardening (/etc/ssh/sshd_config)
Edit with vi/nano:
PermitRootLogin no
PasswordAuthentication no      # only if you already put keys in place
ChallengeResponseAuthentication no
UsePAM yes
X11Forwarding no
AllowUsers secadmin adminuser  # restrict to specific users
Then restart:
systemctl restart sshd
5) Fail2ban (install & basic jail for SSH)
yum -y install epel-release
yum -y install fail2ban
cat > /etc/fail2ban/jail.d/00-sshd.local <<'EOF'
[sshd]
enabled = true
port = ssh
filter = sshd
logpath = /var/log/secure
maxretry = 5
bantime = 3600
EOF
systemctl enable --now fail2ban
6) HTTP/HTTPS (Apache) quick hardening
•	Remove default pages, disable directory listing:
o	In /etc/httpd/conf/httpd.conf or site config, ensure:
o	<Directory /var/www/html>
o	  Options -Indexes
o	</Directory>
•	Ensure TLS parameters in /etc/httpd/conf.d/ssl.conf or your vhost disable weak ciphers:
o	Use Mozilla TLS recommendations if possible (set SSLCipherSuite, SSLProtocol -all +TLSv1.2 +TLSv1.3 if available).
•	Reload:
systemctl restart httpd
7) DNS (named/BIND) hardening
•	In /etc/named.conf:
o	recursion no; or restrict recursion to trusted nets.
o	allow-transfer { none; }; and allow-query limited if needed.
•	Restart:
systemctl restart named
8) vsftpd (FTP) basics (/etc/vsftpd/vsftpd.conf)
anonymous_enable=NO
local_enable=YES
write_enable=YES   # if needed
chroot_local_user=YES
ssl_enable=YES
rsa_cert_file=/etc/ssl/private/vsftpd.pem
Restart:
systemctl restart vsftpd
Passive FTP may require opening a port range — avoid if not necessary.
9) Samba (SMB) basics (/etc/samba/smb.conf)
[global]
   server string = TeamServer
   smb ports = 445
   client min protocol = SMB2
   server min protocol = SMB2
   map to guest = Never
   security = user
Restart:
systemctl restart smb nmb
10) Quick verifications
# check services
systemctl status httpd named vsftpd smb sshd

# listening ports
ss -tulpn | egrep ':(80|443|22|53|21|445)'

# curl http
curl -I http://localhost
curl -I https://localhost

# dig
dig @localhost yourdomain +short
________________________________________
D. Debian 12
1) Update
apt update && apt -y upgrade
2) Firewall (ufw simple)
apt -y install ufw
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
To restrict SSH to a subnet:
ufw allow from 10.0.0.0/24 to any port 22 proto tcp
3) SSH hardening (/etc/ssh/sshd_config)
Same as CentOS example:
PermitRootLogin no
PasswordAuthentication no
AllowUsers secadmin adminuser
Restart:
systemctl restart ssh
4) Fail2ban
apt -y install fail2ban
cat > /etc/fail2ban/jail.d/sshd.local <<'EOF'
[sshd]
enabled = true
maxretry = 5
bantime = 3600
EOF
systemctl restart fail2ban
5) HTTP/HTTPS, DNS, FTP, SMB same hardening steps as CentOS — use package names apache2, bind9, vsftpd, samba.
6) Verify
systemctl status apache2 bind9 vsftpd smbd ssh
ss -tulpn | egrep ':(80|443|22|53|21|445)'
curl -I http://localhost
dig @localhost example.com
________________________________________
Service-specific notes & checks
HTTP/HTTPS
•	Verify TLS: openssl s_client -connect localhost:443 -servername yoursite.example.com (check cert chain + protocol).
•	Ensure automatic redirect from 80→443 if site must be HTTPS.
•	Remove default web content, put a simple status page /var/www/html/index.html with uptime info for judges.
SSH
•	Verify login as non-root key user:
•	ssh -i /path/to/key secadmin@host
•	Test from allowed IP and disallowed IP (or simulate) to confirm firewall rules.
RDP
•	Test remote desktop from allowed team machine; ensure NLA prompts for credentials.
•	If RDP must be public, consider using temporary port change and strong password + 2FA (if feasible).
DNS
•	Test resolution:
•	dig @<your-dns-server> example.com
•	dig @<your-dns-server> www.example.com
•	Check recursion and zone transfer behavior:
•	dig @<your-dns-server> some-internal-zone axfr
FTP / SMB
•	If FTP required, prefer FTPS — validate TLS connection and chroot.
•	For SMB, ensure shares have explicit ACLs and map to guest = Never.
________________________________________
Live monitoring & triage commands (do these ASAP and keep them running)
Linux (use a separate terminal per host)
# follow auth/security logs
tail -F /var/log/secure /var/log/auth.log

# follow web server error/access logs
tail -F /var/log/httpd/error_log /var/log/httpd/access_log   # CentOS Apache
tail -F /var/log/apache2/error.log /var/log/apache2/access.log  # Debian

# realtime systemd/journal
journalctl -f
Windows
•	Watch Security and System logs (Event Viewer) or via PowerShell:
Get-WinEvent -LogName Security -MaxEvents 50 | Format-Table TimeCreated,Id,Message -AutoSize
Get-WinEvent -LogName System -MaxEvents 30
# Continuously (PowerShell loop)
while ($true) { Get-WinEvent -LogName Security -MaxEvents 20; Start-Sleep -Seconds 5 }
Quick network capture if needed
•	Linux:
tcpdump -i any -nn -s0 -w /tmp/capture.pcap port 22 or port 80 or port 443 or port 53
•	Windows: use built-in Message Analyzer (if available) or Wireshark on management machine to capture traffic.
Blocking a malicious IP
•	Linux (firewalld rich rule):
firewall-cmd --permanent --add-rich-rule='rule family="ipv4" source address="1.2.3.4" reject'
firewall-cmd --reload
•	Debian (ufw):
ufw deny from 1.2.3.4
•	Windows:
New-NetFirewallRule -DisplayName "Block 1.2.3.4" -Direction Inbound -RemoteAddress 1.2.3.4 -Action Block
