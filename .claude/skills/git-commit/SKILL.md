---
name: git-commit
description: Stage, commit, and push changes with proper branch checks
disable-model-invocation: true
user-invocable: true
allowed-tools: Bash(git:*)
---

# Git Commit & Push

Stage all modified files, create a commit, and push to the remote.

## Steps

1. Run `git status` (never use `-uall` flag) and `git diff` and `git log --oneline -5` in parallel to understand changes and commit style.

2. Check the current branch:
   - NEVER force push to `main` or `master`.
   - If the branch does not track a remote yet, push with `-u` flag.

3. Analyze all changes and draft a concise commit message:
   - Summarize the nature of the changes (new feature, enhancement, bug fix, refactor, etc.).
   - Use "Add" for new features, "Update" for enhancements, "Fix" for bug fixes.
   - Keep to 1-2 sentences focused on the "why" not the "what".
   - Do NOT commit files that likely contain secrets (`.env`, credentials, etc.).

4. Stage relevant files by name (prefer specific files over `git add -A` or `git add .`).

5. Create the commit using a HEREDOC for the message:
   ```
   git commit -m "$(cat <<'EOF'
   Commit message here.

   Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>
   EOF
   )"
   ```

6. If `$ARGUMENTS` contains "push", ask the user for confirmation before pushing. If confirmed, push to remote.
   - Otherwise, do NOT push — only commit locally.

7. Run `git status` to verify success.

## Rules

- NEVER amend existing commits unless explicitly asked. Always create NEW commits.
- NEVER skip hooks (`--no-verify`) or bypass signing unless explicitly asked.
- NEVER use `-i` flag (interactive) with any git command.
- If a pre-commit hook fails, fix the issue and create a NEW commit (do NOT amend).
- If `$ARGUMENTS` is provided, use it as guidance for the commit message.
