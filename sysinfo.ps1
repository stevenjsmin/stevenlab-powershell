#!/usr/bin/env pwsh


# System Information for Linux -----

Write-Host "=== SYSTEM INFO ==="
Write-Host "Hostname     : $(hostname)"
Write-Host "OS           : $((uname -s) + ' ' + (uname -r))"
Write-Host "PowerShell   : $($PSVersionTable.PSVersion)"
Write-Host "Current user : $env:USER"
Write-Host ""

Write-Host "=== CPU INFO ==="
# Get one model name line from /proc/cpuinfo
bash -c "grep 'model name' /proc/cpuinfo | head -1"

Write-Host "`n=== MEM INFO ==="
bash -c "free -h"

Write-Host "`n=== DISK INFO ==="
Get-PSDrive -PSProvider FileSystem |
    Select-Object Name,@{n='Used(GB)';e={[math]::Round($_.Used/1GB,1)}},
                  @{n='Free(GB)';e={[math]::Round($_.Free/1GB,1)}} |
    Format-Table -AutoSize
