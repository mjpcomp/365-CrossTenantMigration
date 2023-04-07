# TARGET TENANT SCRIPT
# Ensure the $outfile on the desktop created by the SOURCE TENANT SCRIPT exists
# Open a PowerShell connection
# Install-Module -Name ExchangeOnlineManagement (if not installed)
# Import-Module ExchangeOnlineManagement
# Connect-ExchangeOnline -UserPrincipalName <AdministrativeUserAccount> -UseRPSSession
# This will import users from the source tenant using the exported file created by the SOURCE TENANT SCRIPT
$organization = "@DOMAIN.onmicrosoft.com"
$orgdomain = "@DOMAIN.NAME"
$crossTenantDest = "NAME"
# Edit the above to match the appropriate TARGET TENANT information, the $orgdomain will become the PRIMARY SMTP address
# The $crossTenantDest should be the SAME as it was in the SOURCE (this is used to read the correct input file for parsing)

function Get-RandomPassword {
    param (
        [Parameter(Mandatory)]
        [ValidateRange(4,[int]::MaxValue)]
        [int] $length,
        [int] $upper = 1,
        [int] $lower = 1,
        [int] $numeric = 1,
        [int] $special = 1
    )
    if($upper + $lower + $numeric + $special -gt $length) {
        throw "number of upper/lower/numeric/special char must be lower or equal to length"
    }
    $uCharSet = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
    $lCharSet = "abcdefghijklmnopqrstuvwxyz"
    $nCharSet = "0123456789"
    $sCharSet = "!@#$%^&*"
    $charSet = ""
    if($upper -gt 0) { $charSet += $uCharSet }
    if($lower -gt 0) { $charSet += $lCharSet }
    if($numeric -gt 0) { $charSet += $nCharSet }
    if($special -gt 0) { $charSet += $sCharSet }
    
    $charSet = $charSet.ToCharArray()
    $rng = New-Object System.Security.Cryptography.RNGCryptoServiceProvider
    $bytes = New-Object byte[]($length)
    $rng.GetBytes($bytes)
 
    $result = New-Object char[]($length)
    for ($i = 0 ; $i -lt $length ; $i++) {
        $result[$i] = $charSet[$bytes[$i] % $charSet.Length]
    }
    $password = (-join $result)
    $valid = $true
    if($upper   -gt ($password.ToCharArray() | Where-Object {$_ -cin $uCharSet.ToCharArray() }).Count) { $valid = $false }
    if($lower   -gt ($password.ToCharArray() | Where-Object {$_ -cin $lCharSet.ToCharArray() }).Count) { $valid = $false }
    if($numeric -gt ($password.ToCharArray() | Where-Object {$_ -cin $nCharSet.ToCharArray() }).Count) { $valid = $false }
    if($special -gt ($password.ToCharArray() | Where-Object {$_ -cin $sCharSet.ToCharArray() }).Count) { $valid = $false }
 
    if(!$valid) {
         $password = Get-RandomPassword $length $upper $lower $numeric $special
    }
    return $password | ConvertTo-SecureString -AsPlainText
}

$mailboxes = Import-Clixml $home\desktop\UsersToMigrate-$crossTenantDest.xml
foreach ($m in $mailboxes) {
    $mosi = $m.Alias + $organization
	$mosd = $m.Alias + $orgdomain
    $Password = Get-RandomPassword 16
    $x500 = "x500:" + $m.LegacyExchangeDn
    $tmpUser = New-MailUser -MicrosoftOnlineServicesID $mosi -PrimarySmtpAddress $mosd -ExternalEmailAddress $mosi -FirstName $m.FirstName -LastName $m.LastName -Name $m.Name -DisplayName $m.DisplayName -Alias $m.Alias -Password $Password
    $tmpUser | Set-MailUser -EmailAddresses @{add = $x500,$mosi } -ExchangeGuid $m.ExchangeGuid -ArchiveGuid $m.ArchiveGuid -CustomAttribute1 "Cross-Tenant-Migration-Completed"
    $tmpx500 = $m.EmailAddresses | Where-Object { $_ -match "x500" }
    $tmpx500 | ForEach-Object { Set-MailUser $m.Alias -EmailAddresses @{add = "$_" } }
}
