#Requires -Modules Az.PostgreSql

<#
.SYNOPSIS
    Deploy AdventureWorks sample database to Azure Database for PostgreSQL Flexible Server.

.DESCRIPTION
    All-in-one script that provisions an Azure PostgreSQL Flexible Server, enables
    required extensions, creates the adventureworks database, restores the backup,
    and verifies the deployment. Run this single command to get a working
    AdventureWorks database on Azure.

.PARAMETER ServerName
    Name for the PostgreSQL Flexible Server (will be lowercased).

.PARAMETER AdminPassword
    Administrator password. Must be 8-128 characters with uppercase, lowercase,
    numbers, and special characters.

.PARAMETER Location
    Azure region. Default: eastus.

.PARAMETER ResourceGroupName
    Resource group name. Default: adventureworks-rg.

.PARAMETER SkuTier
    Compute tier. Default: Burstable (cheapest option, ~$12-15/month).

.PARAMETER Sku
    SKU name. Default: Standard_B1ms.

.PARAMETER PostgreSqlVersion
    PostgreSQL version. Default: 16.

.EXAMPLE
    ./Deploy-AdventureWorks.ps1 -ServerName "myawserver" -AdminPassword "YourSecureP@ssw0rd!"

.EXAMPLE
    ./Deploy-AdventureWorks.ps1 -ServerName "myawserver" -AdminPassword "YourSecureP@ssw0rd!" -Location "westus2" -SkuTier "GeneralPurpose" -Sku "Standard_D2s_v3"
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string]$ServerName,

    [Parameter(Mandatory)]
    [string]$AdminPassword,

    [string]$Location = "eastus",
    [string]$ResourceGroupName = "adventureworks-rg",

    [ValidateSet("Burstable", "GeneralPurpose", "MemoryOptimized")]
    [string]$SkuTier = "Burstable",

    [string]$Sku = "Standard_B1ms",

    [ValidateRange(11, 17)]
    [int]$PostgreSqlVersion = 16,

    [ValidateSet(32768, 65536, 131072, 262144, 524288)]
    [int]$StorageInMb = 32768
)

$ErrorActionPreference = "Stop"
$ServerName = $ServerName.ToLower()
$BackupFile = Join-Path $PSScriptRoot "AdventureWorksPG.gz"

# --- Validation ---
Write-Host ""
Write-Host "=== AdventureWorks Deployment ===" -ForegroundColor Cyan
Write-Host ""

if (-not (Test-Path $BackupFile)) {
    Write-Error "Database backup not found: $BackupFile. Run this script from the repository root."
    return
}

# Check for psql
$psqlPath = Get-Command psql -ErrorAction SilentlyContinue
if (-not $psqlPath) {
    Write-Warning "psql not found in PATH. You will need psql to create the database and verify the restore."
    Write-Warning "Install PostgreSQL client tools or add the PostgreSQL bin directory to your PATH."
}

# Check for pg_restore
$pgRestorePath = Get-Command pg_restore -ErrorAction SilentlyContinue
if (-not $pgRestorePath) {
    Write-Error "pg_restore not found in PATH. Install PostgreSQL client tools or add the PostgreSQL bin directory to your PATH."
    return
}

# Azure login check
if (-not (Get-AzContext)) {
    Write-Host "No Azure context found. Logging in..." -ForegroundColor Yellow
    Connect-AzAccount
}

# --- Step 1: Resource Group ---
Write-Host "[1/6] Checking resource group '$ResourceGroupName'..." -ForegroundColor Green
if (-not (Get-AzResourceGroup -Name $ResourceGroupName -ErrorAction SilentlyContinue)) {
    Write-Host "  Creating resource group '$ResourceGroupName' in '$Location'..."
    New-AzResourceGroup -Name $ResourceGroupName -Location $Location | Out-Null
}

# --- Step 2: PostgreSQL Flexible Server ---
Write-Host "[2/6] Creating PostgreSQL Flexible Server '$ServerName'..." -ForegroundColor Green
Write-Host "  Tier: $SkuTier | SKU: $Sku | Version: $PostgreSqlVersion | Storage: $($StorageInMb / 1024) GB"
Write-Host "  This may take 2-5 minutes..."

$securePassword = ConvertTo-SecureString $AdminPassword -AsPlainText -Force
$serverParams = @{
    Name                       = $ServerName
    ResourceGroupName          = $ResourceGroupName
    Location                   = $Location
    AdministratorUsername       = "postgres"
    AdministratorLoginPassword = $securePassword
    SkuTier                    = $SkuTier
    Sku                        = $Sku
    Version                    = $PostgreSqlVersion
    StorageInMb                = $StorageInMb
    PublicAccess               = "None"
}

try {
    $server = New-AzPostgreSqlFlexibleServer @serverParams
    $fqdn = $server.FullyQualifiedDomainName
    Write-Host "  Server created: $fqdn" -ForegroundColor Green
}
catch {
    Write-Error "Failed to create server: $_"
    return
}

# --- Step 3: Firewall Rule ---
Write-Host "[3/6] Configuring firewall rule..." -ForegroundColor Green
try {
    $myIP = (Invoke-RestMethod -Uri https://ipinfo.io/json -TimeoutSec 10).ip
    Write-Host "  Adding firewall rule for IP: $myIP"

    New-AzPostgreSqlFlexibleServerFirewallRule `
        -ResourceGroupName $ResourceGroupName `
        -ServerName $ServerName `
        -FirewallRuleName "deploy-script-access" `
        -StartIpAddress $myIP `
        -EndIpAddress $myIP | Out-Null
}
catch {
    Write-Warning "Could not auto-detect IP or create firewall rule."
    Write-Warning "Please add your IP address manually in the Azure Portal."
}

# --- Step 4: Enable Extensions ---
Write-Host "[4/6] Enabling required extensions (TABLEFUNC, UUID-OSSP)..." -ForegroundColor Green
try {
    # Enable extensions via server parameter
    Update-AzPostgreSqlFlexibleServerConfiguration `
        -ResourceGroupName $ResourceGroupName `
        -ServerName $ServerName `
        -Name "azure.extensions" `
        -Value "TABLEFUNC,UUID-OSSP" | Out-Null
    Write-Host "  Extensions enabled. Server may take a moment to apply changes."
    Start-Sleep -Seconds 10
}
catch {
    Write-Warning "Could not enable extensions automatically: $_"
    Write-Warning "Please enable TABLEFUNC and UUID-OSSP manually:"
    Write-Warning "  Azure Portal -> PostgreSQL Server -> Server parameters -> azure.extensions"
}

# --- Step 5: Create Database and Restore ---
Write-Host "[5/6] Creating database and restoring AdventureWorks backup..." -ForegroundColor Green

$env:PGPASSWORD = $AdminPassword

# Create database
Write-Host "  Creating 'adventureworks' database..."
try {
    psql -h $fqdn -U postgres -c "CREATE DATABASE adventureworks;" 2>&1 | Out-Null
}
catch {
    Write-Warning "Database creation may have failed: $_"
}

# Restore backup
Write-Host "  Restoring AdventureWorksPG.gz (this may take 1-3 minutes)..."
pg_restore -h $fqdn -U postgres -d adventureworks $BackupFile 2>&1 | Out-Null

# --- Step 6: Verify ---
Write-Host "[6/6] Verifying deployment..." -ForegroundColor Green

$verifyQuery = @"
SELECT schemaname, COUNT(*) as table_count
FROM pg_tables
WHERE schemaname IN ('humanresources','person','production','purchasing','sales')
GROUP BY schemaname
ORDER BY schemaname;
"@

$result = psql -h $fqdn -U postgres -d adventureworks -c $verifyQuery 2>&1
Write-Host $result

$rowCount = psql -h $fqdn -U postgres -d adventureworks -t -c "SELECT COUNT(*) FROM sales.salesorderheader;" 2>&1
Write-Host "  Sales orders: $($rowCount.Trim()) rows"

# Clear password from environment
Remove-Item Env:\PGPASSWORD -ErrorAction SilentlyContinue

# --- Summary ---
Write-Host ""
Write-Host "=== Deployment Complete ===" -ForegroundColor Cyan
Write-Host ""
Write-Host "  Server:   $fqdn"
Write-Host "  Database: adventureworks"
Write-Host "  Username: postgres"
Write-Host ""
Write-Host "  Connect:  psql `"host=$fqdn port=5432 dbname=adventureworks user=postgres`""
Write-Host ""
Write-Host "  Cleanup:  Remove-AzResourceGroup -Name '$ResourceGroupName' -Force" -ForegroundColor Yellow
Write-Host ""
