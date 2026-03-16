# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/).

## [Unreleased]

### Added
- All-in-one deployment script (`Deploy-AdventureWorks.ps1`) for single-command setup
- Bash deployment script (`deploy-adventureworks.sh`) for Mac/Linux users
- MIT LICENSE file
- CONTRIBUTING.md with contribution guidelines
- Troubleshooting guide (`docs/troubleshooting.md`)
- SQL and PowerShell instruction files for Copilot agents
- Architecture diagram in README
- GitHub Actions CI workflow for validation

### Changed
- Complete README rewrite with quickstart, prerequisites, and troubleshooting
- Improved `CreatePostgreSQLFlexibleServer.ps1` with better error handling and HTTPS
- Specialized all Teamwork agent files for PostgreSQL/database domain
- Updated Makefile with database-specific targets (restore, verify, provision)
- Expanded .gitignore with common patterns
- Updated MEMORY.md to reflect current state

### Removed
- Irrelevant Teamwork agents (api-agent, dependency-manager)
- dependency-update workflow skill
- Go instructions file (no Go code in project)

## [1.0.0] - 2021-09

### Added
- Initial AdventureWorks 2016 PostgreSQL conversion
- `CreatePostgreSQLFlexibleServer.ps1` provisioning script
- `AdventureWorksPG.gz` database backup
- Setup documentation with screenshots
- Azure Database for PostgreSQL Flexible Server support
