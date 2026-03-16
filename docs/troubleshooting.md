# Troubleshooting

Common issues when deploying AdventureWorks to Azure Database for PostgreSQL Flexible Server.

## Connection Issues

### `could not connect to server: Connection refused`

**Cause:** Firewall rules don't allow your IP address.

**Fix:**
1. Find your public IP: visit https://whatismyip.com
2. In Azure Portal → PostgreSQL Server → **Networking**
3. Add a firewall rule for your IP address
4. Or use the deployment script which adds a firewall rule automatically

### `password authentication failed for user "postgres"`

**Cause:** Incorrect password or password doesn't meet Azure complexity requirements.

**Fix:**
- Passwords must be 8-128 characters
- Must include characters from at least 3 categories: uppercase, lowercase, numbers, special characters
- Reset the password in Azure Portal → PostgreSQL Server → **Reset password**

### `FATAL: no pg_hba.conf entry for host`

**Cause:** SSL is required but your client isn't using it.

**Fix:**
```bash
psql "host=YOUR_SERVER.postgres.database.azure.com port=5432 dbname=adventureworks user=postgres sslmode=require"
```

## Extension Issues

### `ERROR: extension "tablefunc" is not available`

**Cause:** Required extensions not enabled in Azure.

**Fix:**
1. Azure Portal → PostgreSQL Server → **Server parameters**
2. Search for `azure.extensions`
3. Enable **TABLEFUNC** and **UUID-OSSP**
4. Click **Save** (server will restart)
5. Wait 1-2 minutes, then retry

Or with Azure CLI:
```bash
az postgres flexible-server parameter set \
    --resource-group YOUR_RG \
    --server-name YOUR_SERVER \
    --name azure.extensions \
    --value "TABLEFUNC,UUID-OSSP"
```

## Restore Issues

### `pg_restore: command not found`

**Cause:** PostgreSQL client tools not in your PATH.

**Fix (Windows):**
```powershell
# Find your PostgreSQL installation
Get-ChildItem "C:\Program Files\PostgreSQL" -Recurse -Filter pg_restore.exe | Select-Object FullName

# Add to PATH (for current session)
$env:PATH += ";C:\Program Files\PostgreSQL\16\bin"
```

**Fix (macOS):**
```bash
# Install via Homebrew
brew install libpq
echo 'export PATH="/opt/homebrew/opt/libpq/bin:$PATH"' >> ~/.zshrc
source ~/.zshrc
```

**Fix (Linux):**
```bash
sudo apt-get install postgresql-client  # Debian/Ubuntu
sudo yum install postgresql             # RHEL/CentOS
```

### `pg_restore: error: role "postgres" does not exist`

**Cause:** The admin username on your server is not `postgres`.

**Fix:** Recreate the server with `postgres` as the admin username. The AdventureWorks backup has all objects owned by `postgres` and cannot be restored under a different user without manual ownership changes.

### Azure extension errors during restore

```
pg_restore: error: could not execute query: ERROR: extension "plpgsql" is not available
```

**These errors are safe to ignore.** Azure manages certain extensions internally. The restore completes successfully despite these warnings. You'll see exactly 2 such errors.

### `pg_restore: error: could not open input file`

**Cause:** Wrong path to `AdventureWorksPG.gz`.

**Fix:** Make sure you're running pg_restore from the repository directory, or provide the full path:
```bash
pg_restore -h YOUR_SERVER -U postgres -d adventureworks /full/path/to/AdventureWorksPG.gz
```

## PowerShell Script Issues

### `The term 'Az.PostgreSql' is not recognized`

**Cause:** Azure PowerShell module not installed.

**Fix:**
```powershell
Install-Module -Name Az.PostgreSql -Force -AllowClobber
```

### `No Azure context found`

**Cause:** Not logged in to Azure.

**Fix:**
```powershell
Connect-AzAccount
# If you have multiple subscriptions:
Set-AzContext -SubscriptionId "YOUR_SUBSCRIPTION_ID"
```

## Azure CLI Issues

### `az: command not found`

**Cause:** Azure CLI not installed.

**Fix:** Install from https://docs.microsoft.com/cli/azure/install-azure-cli

Then login:
```bash
az login
```

## Cost & Cleanup

### How much does this cost?

| SKU Tier | SKU | Approximate Monthly Cost |
|----------|-----|--------------------------|
| Burstable | Standard_B1ms | ~$12-15/month |
| GeneralPurpose | Standard_D2s_v3 | ~$100-130/month |
| MemoryOptimized | Standard_E2s_v3 | ~$130-170/month |

Prices vary by region. Check [Azure pricing](https://azure.microsoft.com/pricing/details/postgresql/flexible-server/) for current rates.

### How do I delete everything when finished?

Delete the entire resource group to remove all resources:

```powershell
# PowerShell
Remove-AzResourceGroup -Name "adventureworks-rg" -Force
```

```bash
# Azure CLI
az group delete --name adventureworks-rg --yes --no-wait
```

> **⚠️ Warning:** This permanently deletes the server and all data. Make sure you don't need anything before running this.
