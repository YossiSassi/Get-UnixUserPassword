# Finds accounts with unixUserPassword in the domain, converts them to clear-text and displays them.
# No dependencies, pure Powershell/ADSI/LDAP (RED - potential cred harvesting; Blue - clear/remove passwords from accounts or modify ACL)
# v1.0 - comments to yossis@protonmail.com

$UnixPwdUsers = ([adsisearcher]'(|(userpassword=*)(unixuserpassword=*))').FindAll();

$ErrorActionPreference = "silentlycontinue"

if ($UnixPwdUsers.Count -gt 0)
    {
        Write-Host "Found $($UnixPwdUsers.Count) relevant users." -ForegroundColor Magenta;
    }
else
    {
        Write-Host "No relevant users found. quiting." -ForegroundColor Yellow;
	break
    }

$UnixPwdUsers | foreach {
    $user = $_;
    Write-Host "User: $($user.Properties.samaccountname) | $($user.Properties.distinguishedname)" -ForegroundColor cyan;
    Write-Host "Raw userPassword: $($user.Properties.userpassword)`nRaw UnixUserPassword: $($user.Properties.unixuserpassword)" -ForegroundColor yellow;
    
    $user.Properties.unixuserpassword -split "`n" -split ' ' | % {$B64pwd+= [char][byte]$_}
    if ($?) {Write-Host "UnixUserPassword convert to decimal: $B64pwd" -ForegroundColor Green}
    $Hexpwd = [system.text.encoding]::Unicode.GetString($([convert]::FromBase64String($B64pwd)))
    if ($?) {Write-Host "UnixUserPassword convert to Hex: $Hexpwd" -ForegroundColor Green}
    
    $user.Properties.userpassword -split "`n" -split ' ' | % {$B64pwd2+= [char][byte]$_}
    if ($?) {Write-Host "UserPassword convert to decimal: $B64pwd2" -ForegroundColor Green}
    $Hexpwd2 = [system.text.encoding]::Unicode.GetString($([convert]::FromBase64String($B64pwd2)))
    if ($?) {Write-Host "UserPassword convert to Hex: $Hexpwd2" -ForegroundColor Green}

    # 2nd method of conversion..
    write-host "userPassword converted with text.encoding --> $([system.text.encoding]::ASCII.GetString( $($user.Properties.userpassword)))";

    Clear-Variable B64pwd, B64pwd2, hexpwd, hexpwd2, user
}

$ErrorActionPreference = "continue"