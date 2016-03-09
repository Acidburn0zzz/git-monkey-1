# Git Monkey

Small Bash utility to monitor Git repositories.   
Git Monkey assumes the branching model is based on git flow.

## Example output

```bash
  🐵  Git Monkey ™

  🐵  Validating master and develop versions
  master and develop are not on same major.minor version.
  master version : v0.3.10
  develop version : v0.4.1

  🐵  Validating changes in master not in develop
  No changes in master not in develop.

  🐵  Verifying outdated feature branches
  No unmerged feature branches.
```
