# Git Instructions

## Push Policy
- **NEVER push to remote without explicitly asking the user for confirmation first.**

## Branch Strategy
Three branch types:

1. **main** — stable, production-ready code
2. **develop** — integration branch for ongoing work
3. **feature branches** — individual features or tasks

### Feature Branch Format
```
feature/<feature-name>
```

## Commit Rules
- If a commit is about to be made on a **non-feature branch** (main or develop), always ask the user if they want to create a new feature branch first before committing.

## GitHub & CI
- Optimize workflow for **GitHub** and **GitHub Actions**.
- Write clear, descriptive commit messages suitable for PR-based workflows.
- Keep commits atomic and focused for clean PR reviews.
