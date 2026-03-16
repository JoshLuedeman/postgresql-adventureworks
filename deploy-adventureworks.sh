#!/usr/bin/env bash
set -euo pipefail

# Deploy AdventureWorks sample database to Azure Database for PostgreSQL Flexible Server
# Usage: ./deploy-adventureworks.sh --server-name myawserver --admin-password 'YourSecureP@ssw0rd!'

# --- Defaults ---
LOCATION="eastus"
RESOURCE_GROUP="adventureworks-rg"
SKU_TIER="Burstable"
SKU="Standard_B1ms"
PG_VERSION="16"
STORAGE_GB="32"
ADMIN_USER="postgres"

# --- Parse Arguments ---
while [[ $# -gt 0 ]]; do
    case "$1" in
        --server-name)     SERVER_NAME="$2"; shift 2;;
        --admin-password)  ADMIN_PASSWORD="$2"; shift 2;;
        --location)        LOCATION="$2"; shift 2;;
        --resource-group)  RESOURCE_GROUP="$2"; shift 2;;
        --sku-tier)        SKU_TIER="$2"; shift 2;;
        --sku)             SKU="$2"; shift 2;;
        --pg-version)      PG_VERSION="$2"; shift 2;;
        --storage-gb)      STORAGE_GB="$2"; shift 2;;
        -h|--help)
            echo "Usage: $0 --server-name NAME --admin-password PASSWORD [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --server-name NAME      PostgreSQL server name (required)"
            echo "  --admin-password PASS   Admin password (required)"
            echo "  --location REGION       Azure region (default: eastus)"
            echo "  --resource-group NAME   Resource group (default: adventureworks-rg)"
            echo "  --sku-tier TIER         Burstable|GeneralPurpose|MemoryOptimized (default: Burstable)"
            echo "  --sku SKU               SKU name (default: Standard_B1ms)"
            echo "  --pg-version VER        PostgreSQL version (default: 16)"
            echo "  --storage-gb GB         Storage in GB (default: 32)"
            exit 0
            ;;
        *) echo "Unknown option: $1"; exit 1;;
    esac
done

# --- Validation ---
if [[ -z "${SERVER_NAME:-}" ]] || [[ -z "${ADMIN_PASSWORD:-}" ]]; then
    echo "Error: --server-name and --admin-password are required."
    echo "Run with --help for usage information."
    exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_FILE="$SCRIPT_DIR/AdventureWorksPG.gz"

if [[ ! -f "$BACKUP_FILE" ]]; then
    echo "Error: Database backup not found: $BACKUP_FILE"
    echo "Run this script from the repository root."
    exit 1
fi

command -v az >/dev/null 2>&1 || { echo "Error: Azure CLI (az) is required. Install from https://docs.microsoft.com/cli/azure/install-azure-cli"; exit 1; }
command -v psql >/dev/null 2>&1 || { echo "Error: psql is required. Install PostgreSQL client tools."; exit 1; }
command -v pg_restore >/dev/null 2>&1 || { echo "Error: pg_restore is required. Install PostgreSQL client tools."; exit 1; }

SERVER_NAME=$(echo "$SERVER_NAME" | tr '[:upper:]' '[:lower:]')

echo ""
echo "=== AdventureWorks Deployment ==="
echo ""

# --- Step 1: Resource Group ---
echo "[1/6] Checking resource group '$RESOURCE_GROUP'..."
if ! az group show --name "$RESOURCE_GROUP" &>/dev/null; then
    echo "  Creating resource group '$RESOURCE_GROUP' in '$LOCATION'..."
    az group create --name "$RESOURCE_GROUP" --location "$LOCATION" --output none
fi

# --- Step 2: PostgreSQL Flexible Server ---
echo "[2/6] Creating PostgreSQL Flexible Server '$SERVER_NAME'..."
echo "  Tier: $SKU_TIER | SKU: $SKU | Version: $PG_VERSION | Storage: ${STORAGE_GB} GB"
echo "  This may take 2-5 minutes..."

az postgres flexible-server create \
    --name "$SERVER_NAME" \
    --resource-group "$RESOURCE_GROUP" \
    --location "$LOCATION" \
    --admin-user "$ADMIN_USER" \
    --admin-password "$ADMIN_PASSWORD" \
    --sku-name "$SKU" \
    --tier "$SKU_TIER" \
    --version "$PG_VERSION" \
    --storage-size "$STORAGE_GB" \
    --public-access "None" \
    --output none

FQDN="${SERVER_NAME}.postgres.database.azure.com"
echo "  Server created: $FQDN"

# --- Step 3: Firewall Rule ---
echo "[3/6] Configuring firewall rule..."
MY_IP=$(curl -s https://ipinfo.io/ip 2>/dev/null || echo "")
if [[ -n "$MY_IP" ]]; then
    echo "  Adding firewall rule for IP: $MY_IP"
    az postgres flexible-server firewall-rule create \
        --resource-group "$RESOURCE_GROUP" \
        --name "$SERVER_NAME" \
        --rule-name "deploy-script-access" \
        --start-ip-address "$MY_IP" \
        --end-ip-address "$MY_IP" \
        --output none
else
    echo "  Warning: Could not detect public IP. Add firewall rule manually in Azure Portal."
fi

# --- Step 4: Enable Extensions ---
echo "[4/6] Enabling required extensions (TABLEFUNC, UUID-OSSP)..."
az postgres flexible-server parameter set \
    --resource-group "$RESOURCE_GROUP" \
    --server-name "$SERVER_NAME" \
    --name "azure.extensions" \
    --value "TABLEFUNC,UUID-OSSP" \
    --output none 2>/dev/null || {
    echo "  Warning: Could not enable extensions automatically."
    echo "  Enable TABLEFUNC and UUID-OSSP in Azure Portal -> Server parameters -> azure.extensions"
}
sleep 10

# --- Step 5: Create Database and Restore ---
echo "[5/6] Creating database and restoring AdventureWorks backup..."
export PGPASSWORD="$ADMIN_PASSWORD"

echo "  Creating 'adventureworks' database..."
psql -h "$FQDN" -U "$ADMIN_USER" -c "CREATE DATABASE adventureworks;" 2>/dev/null || true

echo "  Restoring AdventureWorksPG.gz (this may take 1-3 minutes)..."
pg_restore -h "$FQDN" -U "$ADMIN_USER" -d adventureworks "$BACKUP_FILE" 2>/dev/null || true

# --- Step 6: Verify ---
echo "[6/6] Verifying deployment..."
psql -h "$FQDN" -U "$ADMIN_USER" -d adventureworks -c \
    "SELECT schemaname, COUNT(*) as table_count FROM pg_tables WHERE schemaname IN ('humanresources','person','production','purchasing','sales') GROUP BY schemaname ORDER BY schemaname;"

ROW_COUNT=$(psql -h "$FQDN" -U "$ADMIN_USER" -d adventureworks -t -c "SELECT COUNT(*) FROM sales.salesorderheader;" 2>/dev/null | tr -d ' ')
echo "  Sales orders: $ROW_COUNT rows"

unset PGPASSWORD

# --- Summary ---
echo ""
echo "=== Deployment Complete ==="
echo ""
echo "  Server:   $FQDN"
echo "  Database: adventureworks"
echo "  Username: $ADMIN_USER"
echo ""
echo "  Connect:  psql \"host=$FQDN port=5432 dbname=adventureworks user=$ADMIN_USER\""
echo ""
echo "  Cleanup:  az group delete --name '$RESOURCE_GROUP' --yes --no-wait"
echo ""
