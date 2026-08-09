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
		col_s='\e[1;38;5;130;48;5;234m'
		col_e='\e[0m'
		printf '\n%b%s%b\n' "${col_s}" "${hr}" "${col_e}"
		printf "\e[1mWorktree:\e[0m %s\n" "${wt_dir}"
		cd "${wt_path}"
		smartCommit
		printf '%b%s%b\n\n' "${col_s}" "${hr}" "${col_e}"
	} done
	
	cd "${main_dir}"
}
alias wtsc='(worktree_smartcommit)'
