Import-Module ActiveDirectory
Get-Content .\users.txt | ForEach-Object {
    $u = $_.Trim()
    if ($u) {
        $adUser = Get-ADUser -LDAPFilter "(|(sAMAccountName=$u)(userPrincipalName=$u))" -ErrorAction SilentlyContinue
        if ($adUser) {
            Set-ADObject -Identity $adUser -ProtectedFromAccidentalDeletion:$false -ErrorAction SilentlyContinue
            Disable-ADAccount -Identity $adUser -ErrorAction SilentlyContinue
            Remove-ADUser -Identity $adUser -Confirm:$false
            Write-Host "Deleted $($adUser.SamAccountName)"
        } else {
            Write-Host "Not found: $u"
        }
    }
}
