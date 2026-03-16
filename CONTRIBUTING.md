# Contributing to postgresql-adventureworks

Thank you for your interest in contributing! This repository has two components, and contributions to either are welcome.

## Ways to Contribute

### Database Component
- Improve setup documentation and troubleshooting guides
- Update the PowerShell/Bash deployment scripts
- Report issues with the database restore process
- Add verification queries or validation scripts

### Teamwork Framework Component
- Improve agent definitions (`.github/agents/`)
- Enhance workflow skills (`.github/skills/`)
- Update project conventions and documentation
- See [MEMORY.md](MEMORY.md) for full framework context

## Getting Started

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/your-change`
3. Make your changes following the [conventions](docs/conventions.md)
4. Commit using [Conventional Commits](https://www.conventionalcommits.org/): `feat(docs): add troubleshooting for firewall issues`
5. Push and open a Pull Request

## Pull Request Guidelines

- One logical change per PR
- Title follows Conventional Commits format
- Description includes: what changed, why, and how to verify
- Keep changes focused: aim for ~300 lines and ~10 files maximum

## Reporting Issues

Use the [GitHub issue templates](.github/ISSUE_TEMPLATE/) to report bugs, request features, or propose changes. Include:
- Steps to reproduce (for bugs)
- Expected vs actual behavior
- Azure region and PostgreSQL version (for deployment issues)

## Code of Conduct

Be respectful and constructive. We're all here to make this project better.

## License

By contributing, you agree that your contributions will be licensed under the [MIT License](LICENSE).
