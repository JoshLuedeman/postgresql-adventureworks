# PostgreSQL AdventureWorks — Project Operations
# ================================================
# This Makefile provides common operations for the AdventureWorks
# PostgreSQL database project. Most targets display instructions
# since database operations require server-specific parameters.
#
# Usage: make <target>
#   Run `make help` (or just `make`) to see available targets.

.DEFAULT_GOAL := help

.PHONY: help restore verify provision check clean

# Placeholder variables — override on the command line or via environment
PGHOST ?= localhost
PGPORT ?= 5432
PGUSER ?= postgres
PGDATABASE ?= adventureworks

help: ## Show this help message
	@echo "PostgreSQL AdventureWorks — available targets:"
	@echo ""
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-12s\033[0m %s\n", $$1, $$2}'
	@echo ""

restore: ## Show pg_restore command to load the AdventureWorks database
	@echo "Restore the AdventureWorks database with:"
	@echo ""
	@echo "  pg_restore -h $(PGHOST) -p $(PGPORT) -U $(PGUSER) -d $(PGDATABASE) -v AdventureWorksPG.gz"
	@echo ""
	@echo "Override defaults:  make restore PGHOST=myserver PGPORT=5432 PGUSER=admin PGDATABASE=mydb"

verify: ## Show psql queries to verify the database restore
	@echo "Run these queries to verify the restore:"
	@echo ""
	@echo "  psql -h $(PGHOST) -p $(PGPORT) -U $(PGUSER) -d $(PGDATABASE) -c \"SELECT schema_name FROM information_schema.schemata WHERE schema_name IN ('humanresources','person','production','purchasing','sales') ORDER BY 1;\""
	@echo ""
	@echo "  psql -h $(PGHOST) -p $(PGPORT) -U $(PGUSER) -d $(PGDATABASE) -c \"SELECT schemaname, COUNT(*) AS table_count FROM pg_tables WHERE schemaname IN ('humanresources','person','production','purchasing','sales') GROUP BY schemaname ORDER BY 1;\""

provision: ## Provision an Azure PostgreSQL Flexible Server
	@echo "Run the provisioning script:"
	@echo ""
	@echo "  pwsh ./CreatePostgreSQLFlexibleServer.ps1"
	@echo ""
	@echo "See README.md for prerequisites and parameter details."

check: ## Run pre-commit hooks if available
	@if command -v pre-commit >/dev/null 2>&1; then \
		pre-commit run --all-files; \
	else \
		echo "pre-commit is not installed. Install it with:"; \
		echo "  pip install pre-commit && pre-commit install"; \
	fi

clean: ## Remove temporary files
	@echo "Cleaning temporary files..."
	@rm -rf dist/ bin/ __pycache__/ .pytest_cache/ *.tmp
	@echo "Clean complete."
