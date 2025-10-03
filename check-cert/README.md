## Useage

- Running it with Administrator privileges (PowerShell) will help you avoid permission issues when accessing the LocalMachine store.
- If you only want to view the web server certificates, narrow the search by using -Stores My,WebHosting.

- **Items expiring within the next 30 days only:**
   - .\Get-CertInventory.ps1 -ExpiringInDays 30


- **CSV 내보내기:**
  - .\Get-CertInventory.ps1 -ExportCsv C:\Temp\certs_inventory.csv