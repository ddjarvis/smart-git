# component: worktree-commit

function worktree_smartcommit() {
	main_dir="$PWD"
	worktree_dir=".worktree"
	worktree_path="${main_dir}/${worktree_dir}"
	source_branch="$(git branch --show-current)"
	hr="$(for (( i = 0; i < COLUMNS; i++ )); do printf '='; done)"
	readarray -t wt_dirs  < <(fd -d1 -td . -- "${worktree_path}" | sed -r "s|${worktree_path}/(.+)/|\1|g")
	
	for wt_dir in "${wt_dirs[@]}"; do {
		wt_path="${worktree_path}/${wt_dir}"
		printf '\n%s' "${hr}"
		printf "\e[1mWorktree:\e[0m %s\n" "${wt_dir}"
		cd "${wt_path}"
		smartCommit
		printf '%s\n\n' "${hr}"
	} done
	
	cd "${main_dir}"
}
