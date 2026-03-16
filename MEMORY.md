# Project Memory: postgresql-adventureworks

## Executive Summary

**postgresql-adventureworks** is a dual-purpose repository:

1. **Primary Database Project**: Restores the SQL Server AdventureWorks 2016 database to PostgreSQL, deployable on Azure Database for PostgreSQL Flexible Server
2. **Meta-Framework Repository**: Uses the **Teamwork** agent-native development template for AI-human collaborative development with defined roles, workflows, and coordination protocols

---

## Project Purpose & Audience

### Database Component
- **What**: Converts and restores Microsoft's AdventureWorks 2016 sample database from SQL Server to PostgreSQL format
- **Audience**: Developers, DBAs, learners who need a realistic, multi-table business database for:
  - Learning SQL/PostgreSQL
  - Testing database applications
  - Performance tuning exercises
  - Azure Database demonstrations
- **Use Case**: Quick provisioning of a fully-functional sample database on Azure PostgreSQL Flexible Server

### Teamwork Framework Component
- **What**: The repository itself is a template demonstrating the Teamwork agent-native development framework
- **Audience**: AI-assisted development teams using GitHub Copilot or similar agents
- **Purpose**: Show how to structure agent-human collaboration through roles, skills, and file-based coordination protocols

---

## Tech Stack & Tools

### Database Technology
- **Source Database**: Microsoft SQL Server AdventureWorks 2016 (SQL Server sample database)
- **Target Database**: PostgreSQL (version 11+ supported, tested on v12)
- **Deployment Target**: Azure Database for PostgreSQL Flexible Server
- **Database File**: AdventureWorksPG.gz — prebuilt PostgreSQL dump/backup archive
- **Extensions Required**:
  - TABLEFUNC — used by AdventureWorks schema
  - UUID-OSSP — used by AdventureWorks schema
  - Must be enabled in Azure "Server Parameters" before restore

### Infrastructure & Provisioning
- **Language**: PowerShell (Windows-focused)
- **Azure Modules**: Az.PostgreSQL module for Azure PowerShell
- **Script**: CreatePostgreSQLFlexibleServer.ps1 — wraps Azure PostgreSQL Flexible Server creation
  - Auto-creates resource groups if needed
  - Auto-configures firewall rules for current public IP
  - Parameterized for region, SKU, version, storage

### Client Tools
- **psql**: PostgreSQL command-line client (part of pgAdmin or standalone PostgreSQL installation)
- **pgAdmin 4**: GUI for PostgreSQL server management (used in setup instructions)
- **pg_restore**: PostgreSQL restore utility (used to load the .gz backup)

### Development Workflow Framework
- **Framework**: Teamwork agent-native development template
- **Coordination**: File-based protocols in .teamwork/ directory
  - State files (YAML) track workflow progress
  - Handoff artifacts (Markdown) document role transitions
  - Memory files (YAML) persist patterns and decisions
- **Build System**: GNU Makefile with bash/shell script targets
- **CI/CD Hooks**: GitHub Issues (templates), Pull Requests, GitHub Actions integration
- **Pre-commit**: .pre-commit-config.yaml defines code quality gates
- **Git**: Conventional commits and branch naming (feature/, bugfix/, refactor/, docs/, chore/)

---

## Setup & Usage

### For Database Users: Azure PostgreSQL Deployment

**Step 1: Provision Azure PostgreSQL Flexible Server**
`powershell
# Update CreatePostgreSQLFlexibleServer.ps1 with your parameters:
 = @{
    RGName = "your-resource-group"
    Location = "eastus"
    PGServerName = "your-pg-server"
    PGAdminUserName = "postgres"  # ⚠️  MUST use "postgres" for AdventureWorks
    PGAdminPassword = "YourPassword123!"  # 8-128 chars, 3 of: uppercase, lowercase, numbers, special
    PGSkuTier = "GeneralPurpose"
    PGSku = "Standard_D2s_v3"
    PGVersion = 12  # or higher
    PGStorageInMb = 32768  # 32 GB minimum
}

 = create-AzPGFlexibleServer @PGParams
 = .FullyQualifiedDomainName  # Use this to connect
`

**Step 2: Enable Required PostgreSQL Extensions**
- Navigate to Azure Portal → PostgreSQL Server → Server Parameters
- Find zure.extensions parameter
- Enable: TABLEFUNC, UUID-OSSP
- Click Save (server will restart)

**Step 3: Create dventureworks Database**
`ash
psql -h YOUR_SERVER.postgres.database.azure.com -U postgres -c "CREATE DATABASE adventureworks;"
`

**Step 4: Restore the Backup**
`ash
pg_restore \
  -h YOUR_SERVER.postgres.database.azure.com \
  -U postgres \
  -d adventureworks \
  AdventureWorksPG.gz
`
⚠️  Restore will output 2 Azure extension errors — these are safe to ignore

**Step 5: Connect via pgAdmin**
- Open pgAdmin 4
- Create Server → Register new server with your FQDN and postgres credentials
- Expand database to explore AdventureWorks tables

### For Framework Users: Teamwork Development Setup

**Step 1: Read Project Context**
`ash
# Start every session by reading:
cat MEMORY.md
cat .github/copilot-instructions.md
`

**Step 2: Select Your Agent**
Choose from .github/agents/:
- @planner — break goals into tasks (no coding)
- @architect — design systems, write ADRs (no coding)
- @coder — implement features and tests
- @tester — write adversarial tests (no code changes)
- @reviewer — code review (no modifications)
- @dba-agent — database schema and queries
- Others: security-auditor, documenter, orchestrator, devops, dependency-manager, efactorer

**Step 3: Invoke Workflows**
`ash
# Use Make targets (entry points for skills)
make help                                  # List all targets
make setup                                 # One-time dev environment setup
make lint                                  # Run linters
make test                                  # Run tests
make build                                 # Build project
make check                                 # lint + test + build
make clean                                 # Remove build artifacts

# Special workflow targets
make plan GOAL="your task description"     # Invoke planner agent
make review REF="pr-number"                # Invoke reviewer agent

# CLI build (for Go-based orchestration)
make build-cli                             # Build teamwork CLI binary
make install-cli                           # Install to GOPATH/bin
make test-cli                              # Run Go tests
`

**Step 4: Workflow Skills** (Invoke via Copilot UI or scripting)
- /feature-workflow — add new functionality
- /bugfix-workflow — diagnose and fix bugs
- /refactor-workflow — restructure code
- /hotfix-workflow — urgent production fixes
- /security-response — respond to vulnerabilities
- /release-workflow — prepare and publish releases
- /spike-workflow — research or technical investigation
- /setup-teamwork — auto-detect and fill placeholders

---

## Database Schema: AdventureWorks Structure

The AdventureWorks database is a realistic business sample representing a multinational company's operations. Key schema areas:

### Core Business Tables
- **Sales**: Orders, customers, territories, order details
- **Production**: Products, categories, subcategories, inventory
- **HumanResources**: Employees, departments, job histories
- **Person**: Contacts, addresses, contact types
- **Purchasing**: Vendors, purchase orders, product costs

### Features Demonstrating SQL/DB Concepts
- Complex relationships (foreign keys, cascades)
- Computed columns
- Views and stored procedures
- Triggers
- XML columns
- Hierarchical data (Employee management chains)
- Full-text search capability

### PostgreSQL-Specific Additions
- Uses TABLEFUNC extension for CROSSTAB functionality
- Uses UUID-OSSP extension for UUID generation
- All objects owned by postgres user (required for restore)

---

## Conventions & Patterns

### Git Conventions
**Branch Naming** (Kebab-case with prefix):
- eature/add-column-to-products — new functionality
- ugfix/restore-column-nullability — fixing defects
- efactor/split-large-procedure — restructuring without behavior change
- docs/update-setup-guide — documentation only
- chore/upgrade-postgres-version — tooling/dependencies

**Commit Format** (Conventional Commits):
`
<type>(<scope>): <description>

<optional body explaining why>

Refs: #123
`
Types: eat, ix, docs, efactor, 	est, chore, ci

**Pull Requests**:
- One logical change per PR
- Title = commit format
- Description = what changed, why, how to verify
- Link related issues or ADRs

### Workflow File Structure
`
MEMORY.md                           ← Read first at session start
.github/
  agents/                           ← Custom Agent definitions (role instructions)
  skills/                           ← Workflow Skills (multi-step orchestrations)
  copilot-instructions.md           ← Top-level guidance
.teamwork/
  config.yaml                       ← Project settings (roles, workflows, models)
  state/                            ← Active workflow progress (YAML)
  handoffs/                         ← Structured handoff artifacts between roles
  memory/                           ← Patterns, decisions, feedback
docs/
  conventions.md                    ← Coding/git standards
  architecture.md                   ← ADRs (Architecture Decision Records)
  protocols.md                      ← File-based coordination specification
  glossary.md                       ← Terminology definitions
  role-selector.md                  ← Guide for choosing the right agent
  conflict-resolution.md            ← Resolving conflicting instructions
`

### Quality Gates
All work must pass before handoff:
- ✅ Tests pass (when applicable)
- ✅ Linters pass
- ✅ Handoff artifact complete
- ✅ One task per PR (narrow scope: ~300 lines, ~10 files)

### Documentation Requirements
- Public functions/modules must have doc comments
- README required at project root + major subdirectories
- Comments explain **why**, not **what**
- ADRs for decisions affecting multiple components or constraining future choices

---

## Dependencies & Requirements

### For Database Setup
- **Azure Subscription** with permission to:
  - Create resource groups
  - Create Azure Database for PostgreSQL Flexible Server
  - Configure firewall rules
- **PowerShell 7.0+** (or Windows PowerShell 5.1+)
- **Azure PowerShell Module**: Az.PostgreSQL
- **PostgreSQL Client**: psql (pgAdmin 4 includes this)
- **Network**: Public internet access (for firewall configuration)

### For Development (Teamwork Framework)
- **Make**: GNU Make for invoking targets
- **Bash**: For script execution (scripts/setup.sh, scripts/lint.sh, etc.)
- **Git**: For version control and conventional commits
- **GitHub CLI** (gh): For release automation (optional)
- **Docker**: For containerized testing (optional, used by make docker-build)
- **Go 1.19+**: For building the teamwork CLI (make build-cli)

### Runtime Requirements (PostgreSQL Server)
- **PostgreSQL**: 11 or higher
- **Extensions**: TABLEFUNC, UUID-OSSP (must be enabled in Azure parameters)
- **Storage**: Minimum 32 GB for full AdventureWorks restore
- **Memory**: 2 GB minimum (recommend 4+ for production use)
- **Network**: Private endpoint or firewall rules configured

### Optional Development Tools
- **pgAdmin 4**: GUI for database browsing/management
- **DBeaver**: Alternative SQL IDE with PostgreSQL support
- **Language Servers**: For various language support (specified per agent)
- **Pre-commit Hooks**: Automated code quality checks on commit

---

## Key Decision Records (ADRs)

The project has documented Architecture Decision Records in docs/decisions/:
- **ADR-001**: Role-based agent framework
- **ADR-002**: File-based coordination protocols
- **ADR-003**: Go orchestration CLI
- **ADR-004**: Validate command design
- **ADR-005**: Install/update design
- **ADR-006**: GitHub App worker design
- **ADR-007**: MCP integration strategy
- **ADR-008**: v1.3-v1.5 strategic roadmap

Review these before making architectural changes to understand prior constraints.

---

## Common Tasks

### To restore AdventureWorks to a new Azure PostgreSQL server:
1. Update parameters in CreatePostgreSQLFlexibleServer.ps1
2. Run the PowerShell function to create the server
3. Enable TABLEFUNC and UUID-OSSP extensions in Azure Portal
4. Use pg_restore to load AdventureWorksPG.gz
5. Connect via pgAdmin to verify tables exist

### To contribute to the project:
1. Read MEMORY.md (this file) to understand context
2. Read docs/conventions.md to understand branch naming and commit format
3. Select appropriate agent from .github/agents/ based on task type
4. Follow the agent's responsibilities and boundaries (in its .agent.md file)
5. Make changes, run make check (lint + test + build)
6. Open PR with descriptive title and explanation
7. Update CHANGELOG.md with your changes

### To onboard a new team member or agent:
1. Point them to this MEMORY.md and .github/copilot-instructions.md
2. Have them review docs/conventions.md and docs/role-selector.md
3. Walk through choosing the right agent for their task
4. Point to relevant ADRs if their work touches architecture
5. Emphasize starting each session by reading MEMORY.md

---

## Recent Context & Session Notes

- **Repository Owner**: joshluedeman/postgresql-adventureworks
- **Teamwork Framework Status**: Customized for database project (v1.3.1). Removed irrelevant agents (api-agent, dependency-manager). All remaining agents specialized for PostgreSQL/Azure domain.
- **Database Status**: AdventureWorks 2016 PostgreSQL dump ready for restore (AdventureWorksPG.gz)
- **Deployment Scripts**: `Deploy-AdventureWorks.ps1` (PowerShell) and `deploy-adventureworks.sh` (Bash) — single-command deployment
- **Documentation**: README with quickstart, prerequisites, troubleshooting. Troubleshooting guide in docs/troubleshooting.md.
- **Media**: 8 instructional screenshots in media/ documenting the Azure setup workflow
- **Build System**: Makefile with database-specific targets (restore, verify, provision, check, clean)
- **CI/CD**: GitHub Actions workflow (`.github/workflows/validate.yml`) validates PowerShell/Bash syntax, YAML, Markdown, and secrets
- **Active Agents**: 15 agents (8 core + 4 optional + 3 extended). See .github/agents/ for full list.
- **Quality Gates**: `tests_pass: false`, `lint_pass: false` (manual psql validation; no automated test framework)
- **Framework Review**: 12 upstream improvement issues filed on joshluedeman/teamwork (#126-#137)
- **Open Source**: MIT LICENSE, CONTRIBUTING.md, CHANGELOG.md with full history

---

## Next Steps for New Contributors

1. ✅ Read MEMORY.md (you are here)
2. ✅ Read .github/copilot-instructions.md for workflow guidance
3. ✅ Review docs/conventions.md for coding standards
4. Read docs/role-selector.md to choose your agent
5. Review your agent's full .agent.md file for responsibilities and boundaries
6. Check .teamwork/config.yaml for project settings and model recommendations
7. Review relevant ADRs in docs/decisions/ before architectural changes
8. For database-specific work, review the setup instructions above

---

*This file is the single source of truth for project context. Update it whenever significant decisions are made, patterns emerge, or team learnings accumulate. Keep it brief enough to read in one session (~5 min).*
