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

# Succeed when a merged PR for <branch> had the same tip as the local branch.
# Squash and rebase merges never make the tip an ancestor of the default branch.
gmerged() {
  local tip merged_tips

  command -v gh >/dev/null 2>&1 || return 1
  tip="$(git rev-parse --verify "refs/heads/$1^{commit}" 2>/dev/null)" || return 1
  merged_tips="$(gh pr list --head "$1" --state merged --json headRefOid --jq '.[].headRefOid' 2>/dev/null)" || return 1
  grep -qx -- "${tip}" <<<"${merged_tips}"
}

# Remove a clean worktree for gprune. Return 1 when a guard keeps it, 2 when removal fails.
_gprune_release() {
  local worktree_path="$1" main_worktree="$2" label="$3"

  if [[ "${worktree_path}" == "${main_worktree}" ]]; then
    echo "Skipping ${label}; it is checked out in the main working tree at ${worktree_path}." >&2
    return 1
  fi

  if [[ "${PWD}/" == "${worktree_path}/"* ]]; then
    echo "Skipping ${label}; this shell is inside its worktree." >&2
    return 1
  fi

  if [[ -n "$(git -C "${worktree_path}" status --porcelain)" ]]; then
    echo "Skipping ${label}; its worktree at ${worktree_path} has uncommitted changes."
    return 1
  fi

  echo "Removing worktree for ${label} at ${worktree_path}."
  git worktree remove "${worktree_path}" || return 2
}

# Remove branches and worktrees whose work the default branch or a merged PR already holds.
# A branch goes when one of these holds:
#   - its upstream is gone and the default branch contains its tip or a merged PR matches its tip;
#   - it tracks the default branch and adds no commits;
#   - a merged PR has the same tip, even without an upstream (gco creates branches that way).
# Detached worktrees go when their commit is in the default branch or a remote branch.
# Dirty worktrees, the main working tree, and the current shell's worktree stay.
gprune() {
  local branch upstream worktree_path main_worktree default_branch base tip_in_base
  local record commit detached orphan gitdir

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
    [[ "${branch}" != "${default_branch}" ]] || continue

    tip_in_base=
    git merge-base --is-ancestor "refs/heads/${branch}" "${base}" && tip_in_base=1

    if [[ -n "${upstream}" ]] && ! git show-ref --verify --quiet "${upstream}"; then
      if [[ -z "${tip_in_base}" ]] && ! gmerged "${branch}"; then
        echo "Skipping ${branch}; it is not in ${base} and no merged PR matches its tip." >&2
        continue
      fi
    elif [[ "${upstream}" == "refs/remotes/origin/${default_branch}" && -n "${tip_in_base}" ]]; then
      echo "${branch} tracks ${default_branch} and has no commits of its own."
    elif ! gmerged "${branch}"; then
      continue
    fi

    worktree_path="$(gworktree "${branch}")"
    if [[ -n "${worktree_path}" ]]; then
      _gprune_release "${worktree_path}" "${main_worktree}" "${branch}"
      case $? in
        1) continue ;;
        2) return 1 ;;
      esac
    fi

    git branch -D -- "${branch}" || return
  done < <(git for-each-ref --format='%(refname:short)%09%(upstream)' refs/heads)

  # Detached worktrees have no branch name, so match them by commit.
  worktree_path=
  commit=
  detached=
  while IFS= read -r -d '' record; do
    case "${record}" in
      'worktree '*) worktree_path="${record#worktree }"; commit=; detached= ;;
      'HEAD '*) commit="${record#HEAD }" ;;
      detached) detached=1 ;;
      '')
        if [[ -n "${detached}" && -n "${commit}" && "${worktree_path}" != "${main_worktree}" ]] &&
            { git merge-base --is-ancestor "${commit}" "${base}" ||
              [[ -n "$(git for-each-ref --contains "${commit}" refs/remotes)" ]]; }; then
          _gprune_release "${worktree_path}" "${main_worktree}" "detached HEAD ${commit[1,9]}"
          [[ $? -ne 2 ]] || return 1
        fi
        worktree_path=
        commit=
        detached=
        ;;
    esac
  done < <(git worktree list --porcelain -z)

  git worktree prune

  # Directories left behind after git forgot their worktree. Report them; do not delete them.
  for orphan in "${main_worktree}"-*(N/); do
    [[ -f "${orphan}/.git" ]] || continue
    gitdir="$(sed -n 's/^gitdir: //p' "${orphan}/.git")"
    [[ -e "${gitdir}" ]] && continue
    echo "Orphaned directory, not a registered worktree; left in place: ${orphan}" >&2
  done
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

# Fast-forward the default branch in the canonical checkout and enter it.
# Move the canonical checkout onto the default branch first when that is safe.
# Otherwise fall back to a default-branch worktree, as gco does.
gupdate() {
  local default_branch record canonical current other

  git rev-parse --git-dir >/dev/null 2>&1 || {
    echo "Not inside a Git repository." >&2
    return 1
  }

  git fetch origin || return
  default_branch="$(gdefault)" || return

  IFS= read -r -d '' record < <(git worktree list --porcelain -z)
  canonical="${record#worktree }"
  if [[ "${record}" != 'worktree '* || ! -d "${canonical}" ]]; then
    echo "Cannot find the canonical checkout." >&2
    return 1
  fi

  current="$(git -C "${canonical}" symbolic-ref --quiet --short HEAD 2>/dev/null)"
  if [[ "${current}" != "${default_branch}" ]]; then
    other="$(gworktree "${default_branch}")" || return

    if [[ -n "$(git -C "${canonical}" status --porcelain)" ]]; then
      echo "The canonical checkout at ${canonical} has uncommitted changes; using a ${default_branch} worktree." >&2
    elif [[ -z "${current}" && -z "$(git -C "${canonical}" for-each-ref --contains HEAD refs/heads refs/remotes)" ]]; then
      echo "The canonical checkout has a detached HEAD with unpublished commits; using a ${default_branch} worktree." >&2
    elif [[ -n "${other}" && -n "$(git -C "${other}" status --porcelain)" ]]; then
      echo "The ${default_branch} worktree at ${other} has uncommitted changes; using it." >&2
    else
      # Leave the worktree being removed before git deletes its directory.
      cd -- "${canonical}" || return
      if [[ -n "${other}" ]]; then
        echo "Removing the ${default_branch} worktree at ${other}."
        git worktree remove "${other}" || return
      fi
      git switch "${default_branch}" || return
    fi
  fi

  if [[ "$(git -C "${canonical}" symbolic-ref --quiet --short HEAD 2>/dev/null)" == "${default_branch}" ]]; then
    cd -- "${canonical}" || return
  else
    gco "${default_branch}" || return
  fi
  git merge --ff-only "origin/${default_branch}" || return
  echo "Ready on ${default_branch} in ${PWD}."
}

gfresh() {
  gupdate || return
  gprune
}
