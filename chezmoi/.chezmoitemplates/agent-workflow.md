# Global workflow

## Repositories and worktrees

Use `{{ get . "developmentWorkdir" | default "~/dev" }}` as the development directory. Keep canonical checkouts at `<development-directory>/<repo-name>`.
Keep each canonical checkout on its default branch.
Create task worktrees alongside it at `<development-directory>/<repo-name>-<branch-name>`.
Replace `/` in the branch name with `-` for the directory name. Check for path collisions before creating a worktree.

Before editing repository files, including docs and configuration:

1. Read the repository instructions and inspect Git status and existing worktrees.
2. Reuse the current task's worktree if one exists.
3. Otherwise, use `gco <branch> [base]` to create or enter the task worktree.
4. Move the agent session into that worktree and run subsequent edits and checks there.

Pass a base only when creating a new branch, for example `gco fix/parser HEAD` for work based on the current commit.
Derive the repository name from the canonical checkout, not a worktree directory name.
Use this layout even when an agent offers a different default worktree location.
Read-only work can stay in the canonical checkout. Follow an explicit user request to work elsewhere.

## Shell helpers and cleanup

Use the existing zsh helpers for branch navigation and maintenance:

- `gco <branch> [base]` enters an existing worktree or creates one alongside the canonical checkout.
  Existing local branches retain their commits. Origin-only branches get a local tracking branch.
  New branches start from the locally cached `origin/<default-branch>`, or the local default branch if that ref is unavailable.
  Use an explicit base for stacked work. Fetch first when the task requires the latest remote commits.
  The helper rejects directory collisions and leaves the current worktree's changes in place.
- `gworktree <branch>` prints the branch's worktree path.
- `gupdate` fetches origin, enters the canonical checkout on the default branch, and fast-forwards it.
  If the canonical checkout is on another branch, `gupdate` moves it to the default branch.
  It removes a clean default-branch worktree to do so.
  If the canonical checkout is dirty, or holds unpublished detached commits, `gupdate` uses a default-branch worktree instead.
- `gfresh` runs `gupdate`, then `gprune`.
- `gprune` removes a branch, and its worktree, in one of three cases:
  its upstream is gone and the default branch contains its commits, it tracks the default branch and adds no commits,
  or a merged PR has the same tip as the local branch. The PR check also covers branches with no upstream, such as those `gco` creates.
  It removes clean detached worktrees whose commit is in the default branch or a remote branch.
  It preserves dirty worktrees, the canonical checkout, and the worktree containing the current shell.
  It lists directories that are no longer registered worktrees, and does not delete them.

These are shell functions. If unavailable, source `~/.config/zsh/functions/extra_shell_functions.zsh` in zsh before calling them.
A helper's directory change lasts only within that shell. Update the agent's working directory separately.

Leave task worktrees available for review. When the user requests cleanup, inspect the affected branches before using `gfresh` or `gprune`.
Branches with unmerged commits remain, as do squash-merged branches whose PR tip no longer matches the local tip. Review them manually.
Preserve uncommitted changes and unpublished commits. Never force-remove a worktree to bypass these checks.

## Prose

Load and follow the `no-slop` skill whenever writing or editing human-facing prose.
This includes docs, code comments, ticket updates, communication drafts, commit messages, PR descriptions, and user-facing strings.
Apply it to agent responses too. Follow its structural editing, style, and lint guidance.
If the skill is unavailable through the agent, read `~/.agents/skills/no-slop/SKILL.md` and follow its references.
If that file is also unavailable, report the missing skill and use plain, direct prose.
