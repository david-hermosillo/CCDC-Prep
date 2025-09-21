$userfile = "C:\temp\users.txt"

# Read each line from file
Get-Content $userfile | ForEach-Object {
    $user = $_.Trim()
    if (Get-LocalUser -Name $user -ErrorAction SilentlyContinue) {
        Write-Host "Deleting user: $user"
        Remove-LocalUser -Name $user
    } else {
        Write-Host "User $user does not exist."
    }
}