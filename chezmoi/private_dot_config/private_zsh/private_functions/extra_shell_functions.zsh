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
  elif git show-ref --verify --quiet refs/remotes/origin/main || git show-ref --verify --quiet refs/heads/main; then
    echo main
  elif git show-ref --verify --quiet refs/remotes/origin/master || git show-ref --verify --quiet refs/heads/master; then
    echo master
  else
    echo "Could not determine the default branch. Set origin/HEAD or pass an explicit base to gco." >&2
    return 1
  fi
}

gworktree() {
  local record worktree_path

  if [[ $# -ne 1 ]]; then
    echo "Usage: gworktree <branch>" >&2
    return 2
  fi
  git rev-parse --git-dir >/dev/null 2>&1 || return

  while IFS= read -r -d '' record; do
    case "${record}" in
      'worktree '*) worktree_path="${record#worktree }" ;;
      "branch refs/heads/$1") printf '%s\n' "${worktree_path}"; return 0 ;;
    esac
  done < <(git worktree list --porcelain -z)
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
  local branch upstream worktree_path main_worktree default_branch base

  git rev-parse --git-dir >/dev/null 2>&1 || {
    echo "Not inside a Git repository." >&2
    return 1
  }

  git fetch --all --prune || return
  git worktree prune || return
  default_branch="$(gdefault)" || return
  base="refs/remotes/origin/${default_branch}"
  if ! git show-ref --verify --quiet "${base}"; then
    base="refs/heads/${default_branch}"
  fi
  git rev-parse --verify "${base}^{commit}" >/dev/null || return

  main_worktree="$(git worktree list --porcelain | awk '/^worktree /{print substr($0, 10); exit}')"

  while IFS=$'\t' read -r branch upstream; do
    [[ -n "${upstream}" && "${branch}" != "${default_branch}" ]] || continue
    git show-ref --verify --quiet "${upstream}" && continue
    if ! git merge-base --is-ancestor "refs/heads/${branch}" "${base}"; then
      echo "Skipping ${branch}; it has commits outside ${base}." >&2
      continue
    fi

    worktree_path="$(gworktree "${branch}")"
    if [[ -n "${worktree_path}" ]]; then
      if [[ "${worktree_path}" == "${main_worktree}" ]]; then
        echo "Skipping ${branch}; it is checked out in the main working tree at ${worktree_path}." >&2
        continue
      fi

      if [[ "${PWD}/" == "${worktree_path}/"* ]]; then
        echo "Skipping ${branch}; this shell is inside its worktree." >&2
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
  done < <(git for-each-ref --format='%(refname:short)%09%(upstream)' refs/heads)

  git worktree prune
}

# Enter a branch's worktree, creating it alongside the canonical checkout when needed.
gco() {
  local branch base default_branch worktree_path canonical record

  if [[ $# -lt 1 || $# -gt 2 || "$1" == -* ]]; then
    echo "Usage: gco <branch> [base-for-new-branch]" >&2
    return 2
  fi
  branch="$1"
  base="${2-}"
  git rev-parse --git-dir >/dev/null 2>&1 || return
  git check-ref-format "refs/heads/${branch}" || return

  if [[ $# -eq 2 ]] && { git show-ref --verify --quiet "refs/heads/${branch}" ||
      git show-ref --verify --quiet "refs/remotes/origin/${branch}"; }; then
    echo "A base is only valid for a new branch." >&2
    return 2
  fi

  worktree_path="$(gworktree "${branch}")" || return
  if [[ -n "${worktree_path}" ]]; then
    cd -- "${worktree_path}" || return
    return
  fi

  IFS= read -r -d '' record < <(git worktree list --porcelain -z)
  canonical="${record#worktree }"
  if [[ "${record}" != 'worktree '* || ! -d "${canonical}" ]]; then
    echo "Cannot find the canonical checkout." >&2
    return 1
  fi
  worktree_path="${canonical}-${branch//\//-}"
  if [[ -e "${worktree_path}" || -L "${worktree_path}" ]]; then
    echo "Worktree path already exists: ${worktree_path}" >&2
    return 1
  fi

  if git show-ref --verify --quiet "refs/heads/${branch}"; then
    git worktree add -- "${worktree_path}" "${branch}" || return
  elif git show-ref --verify --quiet "refs/remotes/origin/${branch}"; then
    git worktree add --track -b "${branch}" -- "${worktree_path}" "origin/${branch}" || return
  else
    if [[ -z "${base}" ]]; then
      default_branch="$(gdefault)" || return
      if git show-ref --verify --quiet "refs/remotes/origin/${default_branch}"; then
        base="refs/remotes/origin/${default_branch}"
      else
        base="refs/heads/${default_branch}"
      fi
    fi
    git rev-parse --verify --end-of-options "${base}^{commit}" >/dev/null || return
    git worktree add --no-track -b "${branch}" -- "${worktree_path}" "${base}" || return
  fi

  cd -- "${worktree_path}" || return
}

gupdate() {
  local default_branch

  git rev-parse --git-dir >/dev/null 2>&1 || {
    echo "Not inside a Git repository." >&2
    return 1
  }

  git fetch origin || return
  default_branch="$(gdefault)" || return
  gco "${default_branch}" || return
  git merge --ff-only "origin/${default_branch}" || return
  echo "Ready on ${default_branch}."
}

gfresh() {
  gupdate || return
  gprune
}
