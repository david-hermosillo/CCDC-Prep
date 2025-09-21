# Define download URL for the latest Git for Windows installer (64-bit)
$gitUrl = "https://github.com/git-for-windows/git/releases/latest/download/Git-2.45.2-64-bit.exe"
$gitInstaller = "$env:TEMP\Git-Setup.exe"

# Download Git installer
Invoke-WebRequest -Uri $gitUrl -OutFile $gitInstaller

# Run the installer silently (no GUI, no reboot)
Start-Process -FilePath $gitInstaller -ArgumentList "/VERYSILENT", "/NORESTART" -Wait

# Cleanup
Remove-Item $gitInstaller

# Verify installation
git --version
