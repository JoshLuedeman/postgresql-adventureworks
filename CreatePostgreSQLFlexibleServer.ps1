#Requires -Modules Az.PostgreSQL

if(-not(Get-AzResourceProvider -ProviderNamespace Microsoft.DBforPostgreSQL))
{
    Register-AzResourceProvider -ProviderNamespace Microsoft.DBforPostgreSQL
}

function create-AzPGFlexibleServer
{
<#
Written by:  Tim Chapman, Microsoft  09/2021
.SYNOPSIS
    Wrapper script to quickly create an Azure Database for PostgreSQL Flexible Server

.DESCRIPTION
    Wrapper script to quickly create an Azure Database for PostgreSQL Flexible Server.
    Will create a Resource Group if it doesn't already exist. 
    Will create a firewall rule for your current public IP address.

.EXAMPLE
    $PGParams = @{}
    $PGParams.RGName = "adventureworks-rg"
    $PGParams.Location = "eastus"
    $PGParams.PGServerName = "myawserver"
    $PGParams.PGAdminUserName = "postgres"
    $PGParams.PGAdminPassword = "YourSecureP@ssw0rd!"
    $PGParams.PGSkuTier = "Burstable"
    $PGParams.PGSku = "Standard_B1ms"

    $PGFlexServer = create-AzPGFlexibleServer @PGParams

.PARAMETER RGName
The name of the resource group.  Will be created if it does not exist in the current subscription.

.PARAMETER Location 
Region to put the PostgreSQL Flexible Server.

.PARAMETER PGServerName 
Name of the PostgreSQL Flexible Server

.PARAMETER PGAdminUserName 
Administrator username for the server. Once set, it cannot be changed.

.PARAMETER PGAdminPassword  
The password of the administrator. Minimum 8 characters and maximum 128 characters. Password must contain characters from three of the following categories: English uppercase letters, English lowercase letters, numbers, and non-alphanumeric characters.

.PARAMETER PGSkuTier 
Compute tier of the server. Accepted values: Burstable, GeneralPurpose, Memory Optimized. Default: Burstable.

.PARAMETER PGSku
The name of the sku, typically, tier + family + cores, e.g. Standard_B1ms, Standard_D2ds_v4.

.PARAMETER PGVersion
Version of PostgreSQL to be used

.PARAMETER PGStorageInMb
Max storage allowed for a server.
#>
param(
        [Parameter(Mandatory = $true, Position=0)]
            [string] $RGName  ,
        [Parameter(Mandatory = $true, Position=1)]
            [string] $Location,
        [Parameter(Mandatory = $true, Position=2)]
            [string] $PGServerName ,
        [Parameter(Mandatory = $true, Position=3)]
            [string] $PGAdminUserName,
        [Parameter(Mandatory = $true, Position=4)]
            [string] $PGAdminPassword,
        [Parameter(Position=5)]
        [ValidateSet("GeneralPurpose", "MemoryOptimized", "Burstable")]
            [string] $PGSkuTier = "GeneralPurpose",
        [Parameter(Position=6)]
             [string] $PGSku = "Standard_B1ms",
        [Parameter(Position=7)]
        [ValidateScript({$_ -ge 11 -and $_%1 -eq 0})]
            [int] $PGVersion = 12 ,
        [Parameter(Position = 8)]
        [ValidateSet("32768","65536","131072","262144","524288","1048576","2097152","4194304","8388608","16777216")]
            [int] $PGStorageInMb = 32768
)
    if(-not(Get-AzContext))
    {
        Login-AzAccount
    }

    #servername must be lowercase or the deployment will fail.
    $PGServerName = $PGServerName.ToLower()

    if ($PGAdminUserName -ne "postgres") {
        Write-Warning "Admin username is '$PGAdminUserName'. The AdventureWorks backup requires 'postgres' as the owner. Restore may fail with permission errors."
    }

    $SkuMatch= $false

    if ($PGSkuTier -eq "Burstable" -and $PGSku -like "Standard_B*") 
    {
        $SkuMatch = $true
    }
    elseif ($PGSkuTier -eq "GeneralPurpose" -and $PGSku -like "Standard_D*") 
    {
        $SkuMatch = $true
    }
    elseif ($PGSkuTier -eq "MemoryOptimized" -and $PGSku -like "Standard_E*") 
    {
        $SkuMatch = $true
    }
    else
    {
        Write-Error "SKU and SKU Tier mismatch"
        return
    }

    Write-Verbose "Checking resource group '$RGName'..."
    if(-not(Get-AzResourceGroup -Name $RGName -Location $Location -ErrorAction Ignore))
    {
        $RG = New-AzResourceGroup -Name $RGName -Location $Location
    }

    [SecureString]$Password = ConvertTo-SecureString $PGAdminPassword -AsPlainText -Force
    $PostgreSQLParams = @{}
    $PostgreSQLParams.Name = $PGServerName
    $PostgreSQLParams.ResourceGroupName = $RGName
    $PostgreSQLParams.Location = $Location
    $PostgreSQLParams.AdministratorUsername = $PGAdminUserName 
    $PostgreSQLParams.AdministratorLoginPassword = $Password
    $PostgreSQLParams.SkuTier = $PGSkuTier
    $PostgreSQLParams.Sku = $PGSku
    $PostgreSQLParams.Version = $PGVersion 
    $PostgreSQLParams.StorageInMb = $PGStorageInMb
    $PostgreSQLParams.PublicAccess = "None"

    Write-Verbose "Creating PostgreSQL Flexible Server '$PGServerName' in '$Location'..."
    try {
        $PGServerObject = New-AzPostgreSqlFlexibleServer @PostgreSQLParams
        Write-Verbose "Server '$PGServerName' created successfully."
    }
    catch {
        Write-Error "Failed to create PostgreSQL Flexible Server: $_"
        return $null
    }

    try {
        $MyIPAddress = (Invoke-RestMethod -Uri https://ipinfo.io/json -TimeoutSec 10).ip
    }
    catch {
        Write-Warning "Could not auto-detect public IP address. Please configure firewall rules manually in the Azure Portal."
        Write-Warning "Error: $_"
        return $PGServerObject
    }

    Write-Verbose "Creating firewall rule for IP: $MyIPAddress..."
    $FirewallRuleName = "pgallowedips-$PGServerName"
    $FirewallRules = @{}
    $FirewallRules.ResourceGroupName = $RGName 
    $FirewallRules.ServerName = $PGServerName      
    $FirewallRules.FirewallRuleName = $FirewallRuleName 
    $FirewallRules.StartIpAddress = $MyIPAddress 
    $FirewallRules.EndIpAddress = $MyIPAddress

    $ServerFirewallRule = New-AzPostgreSqlFlexibleServerFirewallRule @FirewallRules

    return $PGServerObject
}

