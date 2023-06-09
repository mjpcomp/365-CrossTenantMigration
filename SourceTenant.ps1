# SOURCE TENANT SCRIPT
# Open a PowerShell connection
# Install-Module -Name ExchangeOnlineManagement (if not installed)
# Import-Module ExchangeOnlineManagement
# Connect-ExchangeOnline -UserPrincipalName <AdministrativeUserAccount> -UseRPSSession
# This will export users from the source tenant with the CustomAttribute1 = "Cross-Tenant-Dest-NAME"
# Make sure the CustomAttribute1 is set within EXCHANGE, under user Mailbox setting -> Others -> Custom Attributes
# The CustomAttribute should NOT have any spaces
$crossTenantDest = "NAME"
# Set the crossTenantDest to the appropriate TARGET TENANT
$outFileUsers = "$home\desktop\UsersToMigrate-$crossTenantDest.txt"
$outFileUsersXML = "$home\desktop\UsersToMigrate-$crossTenantDest.xml"
Get-Mailbox -Filter "CustomAttribute1 -like 'Cross-Tenant-Dest-$crossTenantDest'" -ResultSize Unlimited | Select-Object -ExpandProperty  Alias | Out-File $outFileUsers
$mailboxes = Get-Content $outFileUsers
$mailboxes | ForEach-Object {Get-Mailbox $_} | Select-Object PrimarySMTPAddress,Alias,SamAccountName,FirstName,LastName,DisplayName,Name,ExchangeGuid,ArchiveGuid,LegacyExchangeDn,EmailAddresses | Export-Clixml $outFileUsersXML
