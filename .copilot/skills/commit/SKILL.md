---
name: commit
description: Generate conventional commit messages from staged changes. Analyzes git diff and creates standardized commit messages following the Conventional Commits specification.
user-invokable: true
argument-hint: "[optional: specific files or scope]"
---

# Conventional Commit Skill

Generate standardized commit messages following the [Conventional Commits](https://www.conventionalcommits.org/) specification.

## Workflow

1. Run `git status` to review changed files
2. Run `git diff --cached` to inspect staged changes (or `git diff` for unstaged)
3. Analyze the changes and construct a commit message
4. Execute `git commit -m "type(scope): description"`

## Commit Message Format

```
type(scope): description

[optional body]

[optional footer]
```

## Types

| Type | Description |
|------|-------------|
| `feat` | New feature |
| `fix` | Bug fix |
| `docs` | Documentation only |
| `style` | Formatting, no code change |
| `refactor` | Code restructuring, no behavior change |
| `perf` | Performance improvement |
| `test` | Adding/fixing tests |
| `build` | Build system or dependencies |
| `ci` | CI configuration |
| `chore` | Maintenance tasks |
| `revert` | Revert previous commit |

## Rules

- **Type**: Required. Must be one of the allowed types
- **Scope**: Optional. The area of code affected (e.g., `parser`, `auth`, `api`)
- **Description**: Required. Imperative mood, lowercase, no period (e.g., "add feature" not "Added feature.")
- **Body**: Optional. Explain *what* and *why*, not *how*
- **Footer**: Optional. Breaking changes (`BREAKING CHANGE:`) or issue references (`Fixes #123`)

## Breaking Changes

Add `!` after type/scope and include `BREAKING CHANGE:` in footer:

```
feat(api)!: change auth token format

BREAKING CHANGE: JWT tokens now use RS256 instead of HS256
```

## Examples

```
feat(parser): add ability to parse arrays
fix(ui): correct button alignment on mobile
docs: update README with installation steps
refactor: simplify authentication flow
chore: update dependencies to latest versions
feat!: require Node.js 18+ (BREAKING CHANGE: dropped Node.js 16 support)
```

## Multi-line Commits

For complex changes, use body and footer:

```
fix(auth): prevent session hijacking on token refresh

The previous implementation allowed reuse of expired refresh tokens
within a 5-minute grace window. This change invalidates tokens
immediately upon refresh.

Fixes #142
```
