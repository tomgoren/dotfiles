gbranch() {
	git rev-parse --abbrev-ref HEAD
}

gpub() {
  if [[ $(gbranch) == "main" || $(gbranch) == "master" ]]; then
    echo "You are on main - be on a branch"
  else;
    git push -u origin $(gbranch)
  fi
}

gprune() {
	git remote prune origin
	git fetch -p && git branch -vv --no-color | awk '/: gone]/ {print $1}' | xargs git branch -D
}

gfresh() {
  git checkout main
  git pull
  gprune
  echo "Ready!"
}
