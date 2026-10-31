_gco() {
  local -a branches

  case "${CURRENT}" in
    2)
      branches=(
        "${(@f)$(git for-each-ref --format='%(refname:lstrip=2)' refs/heads 2>/dev/null)}"
        "${(@f)$(git for-each-ref --format='%(if)%(symref)%(then)%(else)%(refname:lstrip=3)%(end)' refs/remotes/origin 2>/dev/null)}"
      )
      ;;
    3)
      branches=(HEAD "${(@f)$(git for-each-ref --format='%(refname:short)' refs/heads refs/remotes refs/tags 2>/dev/null)}")
      ;;
    *) return 1 ;;
  esac

  branches=("${(@u)branches:#}")
  _describe 'branch' branches
}

compdef _gco gco
