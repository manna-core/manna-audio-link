$ErrorActionPreference = "Stop"

$Rows = Get-NetIPConfiguration |
    Where-Object { $_.IPv4DefaultGateway -and $_.NetAdapter.Status -eq "Up" } |
    ForEach-Object {
        $Interface = $_.InterfaceAlias
        $IsVpn = $Interface -match "VPN|Radmin|Tailscale|ZeroTier|WireGuard|OpenVPN"
        [PSCustomObject]@{
            Interface = $Interface
            IPv4 = ($_.IPv4Address | Select-Object -First 1).IPAddress
            Gateway = $_.IPv4DefaultGateway.NextHop
            UseForLaptop = if ($IsVpn) { "only if both use this VPN" } else { "yes" }
        }
    } |
    Sort-Object @{ Expression = { if ($_.UseForLaptop -eq "yes") { 0 } else { 1 } } }, Interface

$Rows | Format-Table -AutoSize

Write-Host ""
Write-Host "Use the Wi-Fi/Ethernet IPv4 for the laptop sender unless both machines intentionally use the same VPN."
Write-Host "Enter that IPv4 address during Manna Send Audio setup on the laptop."
