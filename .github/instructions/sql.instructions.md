---
applyTo: "**/*.sql"
---
# SQL / PostgreSQL Guidelines

- Use lowercase for SQL keywords (select, insert, create table) for readability in PostgreSQL.
- Use snake_case for table names, column names, indexes, and constraints.
- Prefix views with `v_`, functions with `fn_`, and triggers with `trg_`.
- Always specify schema explicitly (e.g., `sales.salesorderheader`, not just `salesorderheader`).
- Use `NOT NULL` constraints by default — allow `NULL` only when justified.
- Include comments on tables and columns using `COMMENT ON` for non-obvious fields.
- Write idempotent migration scripts when possible (use `IF NOT EXISTS`, `IF EXISTS`).
- Keep transactions short — wrap DDL changes in `BEGIN`/`COMMIT` blocks.
- When adding indexes, justify with query patterns or EXPLAIN ANALYZE results.
- Use `pg_restore` for bulk data loads, not INSERT statements.
- Reference the AdventureWorks schema structure: humanresources, person, production, purchasing, sales.
