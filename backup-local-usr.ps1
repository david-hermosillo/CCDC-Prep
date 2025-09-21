$pw = Read-Host -AsSecureString "Enter password for secadmin"
New-LocalUser -Name secadmin -Password $pw -FullName "Competition Admin"
Add-LocalGroupMember -Group "Administrators" -Member "secadmin"
