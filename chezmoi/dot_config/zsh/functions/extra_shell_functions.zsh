gbranch() {
  git symbolic-ref --quiet --short HEAD 2>/dev/null
}

gdefault() {
  local remote_ref

  git rev-parse --git-dir >/dev/null 2>&1 || {
    echo "Not inside a Git repository." >&2
    return 1
  }

  remote_ref="$(git symbolic-ref --quiet --short refs/remotes/origin/HEAD 2>/dev/null)" || true
  if [[ -n "${remote_ref}" ]]; then
    echo "${remote_ref#origin/}"
  elif git show-ref --verify --quiet refs/remotes/origin/main; then
    echo main
  elif git show-ref --verify --quiet refs/remotes/origin/master; then
    echo master
  else
    echo "Could not determine the default branch for origin." >&2
    return 1
  fi
}

gworktree() {
  git worktree list --porcelain | awk -v ref="refs/heads/$1" '
    /^worktree / { path = substr($0, 10) }
    $1 == "branch" && $2 == ref { print path; exit }
  '
}

gpub() {
  local branch default_branch

  git rev-parse --git-dir >/dev/null 2>&1 || {
    echo "Not inside a Git repository." >&2
    return 1
  }

  branch="$(gbranch)" || {
    echo "Cannot publish from a detached HEAD." >&2
    return 1
  }
  default_branch="$(gdefault)" || return

  if [[ "${branch}" == "${default_branch}" ]]; then
    echo "You are on ${default_branch}; switch to a feature branch first." >&2
    return 1
  fi

  git push -u origin "${branch}"
}

gprune() {
  local branch tracking worktree_path main_worktree

  git rev-parse --git-dir >/dev/null 2>&1 || {
    echo "Not inside a Git repository." >&2
    return 1
  }

  git fetch --all --prune || return
  git worktree prune || return

  main_worktree="$(git worktree list --porcelain | awk '/^worktree /{print substr($0, 10); exit}')"

  while IFS=$'\t' read -r branch tracking; do
    [[ "${tracking}" == "[gone]" ]] || continue

    worktree_path="$(gworktree "${branch}")"
    if [[ -n "${worktree_path}" ]]; then
      if [[ "${worktree_path}" == "${main_worktree}" ]]; then
        echo "Skipping ${branch}; it is checked out in the main working tree at ${worktree_path}." >&2
        continue
      fi

      if [[ -n "$(git -C "${worktree_path}" status --porcelain)" ]]; then
        echo "Skipping ${branch}; its worktree at ${worktree_path} has uncommitted changes."
        continue
      fi

      echo "Removing worktree for ${branch} at ${worktree_path}."
      git worktree remove "${worktree_path}" || return
    fi

    git branch -D -- "${branch}" || return
  done < <(git for-each-ref --format='%(refname:short)%09%(upstream:track)' refs/heads)

  git worktree prune
}

gfresh() {
  local current_branch default_branch default_worktree

  git rev-parse --git-dir >/dev/null 2>&1 || {
    echo "Not inside a Git repository." >&2
    return 1
  }

  default_branch="$(gdefault)" || return
  current_branch="$(gbranch)" || true

  if [[ "${current_branch}" != "${default_branch}" ]]; then
    default_worktree="$(gworktree "${default_branch}")"

    if [[ -n "${default_worktree}" ]]; then
      echo "Leaving ${current_branch:-detached HEAD} and moving to the canonical ${default_branch} directory at ${default_worktree}."
      cd "${default_worktree}" || return
    elif git show-ref --verify --quiet "refs/heads/${default_branch}"; then
      git switch "${default_branch}" || return
    else
      git switch --track "origin/${default_branch}" || return
    fi
  fi

  gprune || return

  git merge --ff-only "origin/${default_branch}" || return
  echo "Ready on ${default_branch}."
}
