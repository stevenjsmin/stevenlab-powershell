<#
.SYNOPSIS
  Windows Certificate Inventory Script

.DESCRIPTION
  - Retrieves certificates from CurrentUser / LocalMachine stores and displays them in a table.
  - Default output: Scope, Store, SubjectCN, FriendlyName, IssuerCN, NotBefore, NotAfter, DaysLeft, Thumbprint
  - Options: filter by store, filter by expiration days, export to CSV

.PARAMETER Scope
  Search scope: CurrentUser, LocalMachine, Both (default: Both)

.PARAMETER Stores
  Array of store names (default: My, WebHosting, CA, Root, TrustedPeople, TrustedPublisher)

.PARAMETER ExpiringInDays
  Show only certificates that will expire within n days (default: disabled)

.PARAMETER ExportCsv
  Path to save results as CSV (e.g., C:\Temp\certs.csv). If not specified, results are displayed in console.

.EXAMPLE
  .\Get-CertInventory.ps1
  # Scan both CurrentUser and LocalMachine stores

.EXAMPLE
  .\Get-CertInventory.ps1 -Scope LocalMachine -ExpiringInDays 60
  # Show only LocalMachine certs expiring within 60 days

.EXAMPLE
  .\Get-CertInventory.ps1 -ExportCsv C:\Temp\certs.csv
  # Save results to CSV
#>

[CmdletBinding()]
param(
  [ValidateSet('CurrentUser','LocalMachine','Both')]
  [string]$Scope = 'Both',

  [string[]]$Stores = @('My','WebHosting','CA','Root','TrustedPeople','TrustedPublisher'),

  [int]$ExpiringInDays,

  [string]$ExportCsv
)

function Get-StorePathList {
  param([string]$Scope, [string[]]$Stores)
  $paths = @()
  if ($Scope -in @('CurrentUser','Both')) {
    foreach ($s in $Stores) { $paths += "Cert:\CurrentUser\$s" }
  }
  if ($Scope -in @('LocalMachine','Both')) {
    foreach ($s in $Stores) { $paths += "Cert:\LocalMachine\$s" }
  }
  return $paths
}

function Get-SubjectCN {
  param([string]$Subject)
  # Subject example: "CN=www.example.com, O=Acme Corp, C=AU"
  if ($Subject -match 'CN\s*=\s*([^,]+)') { return $Matches[1].Trim() }
  return $Subject
}

$now = Get-Date
$results = New-Object System.Collections.Generic.List[object]

$storePaths = Get-StorePathList -Scope $Scope -Stores $Stores

foreach ($path in $storePaths) {
  try {
    $certs = Get-ChildItem -Path $path -ErrorAction SilentlyContinue
  } catch {
    continue
  }

  foreach ($c in $certs) {
    $subjectCN  = Get-SubjectCN -Subject $c.Subject
    $issuerCN   = Get-SubjectCN -Subject $c.Issuer
    $dnsNames   = $null
    try { if ($c.DnsNameList) { $dnsNames = ($c.DnsNameList | ForEach-Object { $_.Unicode }) -join ', ' } } catch {}

    $eku = $null
    try {
      if ($c.EnhancedKeyUsageList) {
        $eku = ($c.EnhancedKeyUsageList | ForEach-Object { $_.FriendlyName }) -join '; '
      }
    } catch {}

    $daysLeft = ($c.NotAfter - $now).Days

    $obj = [PSCustomObject]@{
      Scope         = if ($path -like 'Cert:\LocalMachine*') {'LocalMachine'} else {'CurrentUser'}
      Store         = ($path -split '\\')[-1]
      SubjectCN     = $subjectCN
      FriendlyName  = $c.FriendlyName
      DNSNames      = $dnsNames
      IssuerCN      = $issuerCN
      NotBefore     = $c.NotBefore
      NotAfter      = $c.NotAfter
      DaysLeft      = $daysLeft
      Thumbprint    = $c.Thumbprint
      HasPrivateKey = $c.HasPrivateKey
      KeyAlgorithm  = $c.PublicKey.Oid.FriendlyName
      KeyLength     = $c.PublicKey.Key.KeySize
      EKU           = $eku
    }

    if ($PSBoundParameters.ContainsKey('ExpiringInDays')) {
      if ($daysLeft -le $ExpiringInDays) { $results.Add($obj) }
    } else {
      $results.Add($obj)
    }
  }
}

# Sort: by expiration first, then by store, then by subject
$results = $results | Sort-Object @{Expression='DaysLeft'; Ascending=$true}, @{Expression='Store'; Ascending=$true}, @{Expression='SubjectCN'; Ascending=$true}

if ($ExportCsv) {
  $dir = Split-Path -Path $ExportCsv -Parent
  if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir | Out-Null }
  $results | Export-Csv -Path $ExportCsv -NoTypeInformation -Encoding UTF8
  Write-Host "CSV saved to $ExportCsv"
}

# Console output
$results |
  Select-Object Scope, Store, SubjectCN, FriendlyName, IssuerCN, NotAfter, DaysLeft, Thumbprint |
  Format-Table -AutoSize
