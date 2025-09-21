# Disable SMBv1
Set-SmbServerConfiguration -EnableSMB1Protocol $false -Force
# Ensure SMB signing optional/required (if needed)
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters" -Name "RequireSecuritySignature" -Value 1 -Type DWord
Restart-Service -Name LanmanServer
