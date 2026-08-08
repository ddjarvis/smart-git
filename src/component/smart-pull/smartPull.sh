# component: smart-pull

function smartPull() {
	remote=origin
	
	# Try to detect the default branch from origin/HEAD.
	# If that fails, fall back to "main".
	git remote set-head "$remote" --auto >/dev/null 2>&1 || true
	default=$(git symbolic-ref --quiet --short "refs/remotes/$remote/HEAD" 2>/dev/null || echo '')
	default=${default#"$remote/"}
	[ -n "$default" ] || default=main
	
	echo "Using default branch: $default"
	
	# 1. Fetch and prune stale origin/* branches.
	git fetch --prune "$remote"
	
	# Make sure the default branch exists locally.
	if ! git show-ref -q "refs/heads/$default"; then
	  if git show-ref -q "refs/remotes/$remote/$default"; then
	    git branch --track "$default" "refs/remotes/$remote/$default"
	  else
	    echo "ERROR: $remote/$default does not exist, cannot switch to $default" >&2
	    exit 1
	  fi
	fi
	
	# Switch to the default branch early.
	# This prevents trying to delete the currently checked-out branch.
	git switch "$default"
	
	# Update the default branch fast-forward only.
	if git show-ref -q "refs/remotes/$remote/$default"; then
	  git merge --ff-only "$remote/$default" ||
	    echo "WARN: $default could not be fast-forwarded from $remote/$default"
	else
	  echo "WARN: $remote/$default does not exist"
	fi
	
	# 2. For every existing local branch:
	#    - if the same-named remote branch exists, update it if possible
	#    - if the remote branch does not exist, delete the local branch
	for b in $(git for-each-ref --format='%(refname:short)' refs/heads); do
	  [ "$b" = "$default" ] && continue
	
	  if git show-ref -q "refs/remotes/$remote/$b"; then
	    echo "Updating local branch: $b from $remote/$b"
	
	    # Safe fast-forward only.
	    # If the branch has diverged, this will warn instead of destroying local commits.
	    git fetch "$remote" "$b:refs/heads/$b" 2>/dev/null ||
	      echo "WARN: $b exists on $remote but could not be fast-forwarded"
	
	    # Optional: make sure the local branch tracks the remote branch.
	    git branch --set-upstream-to="$remote/$b" "$b" 2>/dev/null || true
	  else
	    echo "Deleting local branch: $b because $remote/$b does not exist"
	
	    # Use -D because squash/rebase-merged PR branches often fail with -d.
	    # If you want safer deletion, change this to:
	    #
	    #   git branch -d "$b"
	    #
	    git branch -D "$b" ||
	      echo "WARN: could not delete $b"
	  fi
	done
	
	# 3. Create local branches for remote branches that do not exist locally.
	for rb in $(git for-each-ref --format='%(refname:short)' "refs/remotes/$remote"); do
	  b=${rb#"$remote/"}
	
	  # Skip the fake origin/HEAD ref.
	  [ "$b" = "HEAD" ] && continue
	  [ "$b" = "$remote" ] && continue
	
	  if ! git show-ref -q "refs/heads/$b"; then
	    echo "Creating local branch: $b from $remote/$b"
	    git branch --track "$b" "refs/remotes/$remote/$b" ||
	      echo "WARN: could not create local branch $b"
	  fi
	done
	
	# 4. Switch back to the default branch.
	git switch "$default"
	
	echo "Done. You are now on: $(git branch --show-current)"
}