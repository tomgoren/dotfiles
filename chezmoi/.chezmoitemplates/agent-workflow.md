# Global workflow

## Repositories and worktrees

Use `{{ get . "developmentWorkdir" | default "~/dev" }}` as the development directory. Keep canonical checkouts at `<development-directory>/<repo-name>`.
Keep each canonical checkout on its default branch.
Create task worktrees alongside it at `<development-directory>/<repo-name>-<branch-name>`.
Replace `/` in the branch name with `-` for the directory name. Check for path collisions before creating a worktree.

Before editing repository files, including docs and configuration:

1. Read the repository instructions and inspect Git status and existing worktrees.
2. Reuse the current task's worktree if one exists.
3. Otherwise, create a task branch and worktree with `git worktree add -b <branch> <path> <base>`.
4. Move the agent session into that worktree and run subsequent edits and checks there.

For an existing branch, omit `-b` and use the branch as the final argument.
Derive the repository name from the canonical checkout, not a worktree directory name.
Use this layout even when an agent offers a different default worktree location.
Read-only work can stay in the canonical checkout. Follow an explicit user request to work elsewhere.

## Shell helpers and cleanup

Use the existing zsh helpers for branch navigation and maintenance:

- `gco <branch>` checks out a branch or enters its existing worktree.
- `gworktree <branch>` prints the branch's worktree path.
- `gfresh` returns to the default branch, runs `gprune`, and fast-forwards from origin.
- `gprune` removes clean worktrees and local branches whose upstream branches are gone.

These are shell functions. If unavailable, source `~/.config/zsh/functions/extra_shell_functions.zsh` in zsh before calling them.
A helper's directory change lasts only within that shell. Update the agent's working directory separately.

Leave task worktrees available for review. When the user requests cleanup, inspect the affected branches before using `gfresh` or `gprune`.
`gprune` force-deletes branches with missing upstreams, even if they contain unmerged commits.
Preserve uncommitted changes and unpublished commits. Never force-remove a worktree to bypass these checks.

## Prose

Load and follow the `no-slop` skill whenever writing or editing human-facing prose.
This includes docs, code comments, ticket updates, communication drafts, commit messages, PR descriptions, and user-facing strings.
Apply it to agent responses too. Follow its structural editing, style, and lint guidance.
If the skill is unavailable through the agent, read `~/.agents/skills/no-slop/SKILL.md` and follow its references.
If that file is also unavailable, report the missing skill and use plain, direct prose.
