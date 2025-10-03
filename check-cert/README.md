## Useage

A PowerShell script that neatly extracts the name (FriendlyName/Subject) and expiration date (NotAfter) for the certificates installed on a Windows server.

This script can check both the Current User and Local Machine stores, filter for certificates that are nearing expiration, and export the results to a CSV file, all in one go.

- Running it with Administrator privileges (PowerShell) will help you avoid permission issues when accessing the LocalMachine store.
- If you only want to view the web server certificates, narrow the search by using -Stores My,WebHosting.

- **Items expiring within the next 30 days only:**
   - .\Get-CertInventory.ps1 -ExpiringInDays 30


- **CSV 내보내기:**
  - .\Get-CertInventory.ps1 -ExportCsv C:\Temp\certs_inventory.csv