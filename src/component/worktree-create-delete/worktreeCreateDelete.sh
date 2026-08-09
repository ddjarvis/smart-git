# component: worktree-create-delete

function kebab_to_camel() {
	str="$1"

	# Split string on hyphens
	IFS='-' read -ra parts <<< "$str"
	
	# Keep the first word lowercase, capitalize subsequent words
	result="${parts[0]}"
	for word in "${parts[@]:1}"; do
	  result+="${word^}"
	done
	
	echo "$result" # myKebabCaseString
}

wt_feats=(
	"smart-commit"
	"smart-pull"
	"smart-init"
	"worktree-create-delete"
	"entry"
	"build"
)

wt_main_dir="$PWD"
wt_worktree_dir=".worktree"
wt_worktree_path="${wt_main_dir}/${wt_worktree_dir}"
wt_source_branch="$(git branch --show-current)"

function wt_create() {
	[[ ! -d "${wt_worktree_path}" ]] && mkdir "${wt_worktree_path}"
	
	for feat in "${wt_feats[@]}"; do {
		feat_path="${wt_worktree_path}/${feat}"
		feat_branch="feat/${feat}"
		if [[ "${feat}" == "build" ]]; then {
			feat_file="build.sh"
			file_dir="${feat_path}"
			file_content='#!/usr/bin/env bash'
		} elif [[ "${feat}" == "entry" ]]; then {
			feat_file="entry.sh"
			file_dir="${feat_path}/src"
			file_content="$(printf '%s\n\n' "# component: ${feat}")"
		} else {
			feat_file="$(kebab_to_camel "${feat}").sh"
			file_dir="${feat_path}/src/component"
			file_content="$(printf '%s\n\n' "# component: ${feat}")"
		} fi
		file_path="${file_dir}/${feat_file}"
		
		echo "Feature: ${feat}"
		git worktree add -b "${feat_branch}" "${feat_path}" "${wt_source_branch}" &>/dev/null \
			&& echo "> created worktree branch [${feat_branch}] from branch [${wt_source_branch}]"
		cd "${feat_path}"
		[[ -f "${feat_path}/src/.gitkeep" ]] \
			&& git rm "${feat_path}/src/.gitkeep" &>/dev/null \
			&& echo "> removed file: ./src/.gitkeep"
		
		[[ ! -d "${file_dir}" ]] \
			&& mkdir -p "${file_dir}" &>/dev/null
			
		touchx "${file_path}" &>/dev/null \
			&& printf '%s\n\n' "${file_content}" >"${file_path}" \
			&& echo "> created file: ./${file_path#"${wt_worktree_path}/"}"
		
		git asp \
			"Created Branch: ${feat}" \
			"- Added file: ./${file_path#"${wt_worktree_path}/"}" &>/dev/null \
			&& echo "> pushed branch [${feat_branch}]"
		
		echo ""
	} done
	cd "${wt_main_dir}"
}
function wt_delete() {
	cd "${wt_main_dir}"
	rm -rf "${wt_worktree_path}"
	git worktree prune
	branchL="$(git branch)"
	branchR="$(git branch -r)"
	for feat in "${wt_feats[@]}"; do {
		branch="feat/${feat}"
		(grep -Eq "^[\*\+]? +$feat_branch" <<< "${branchL}") && git branch -D "${branch}"
		(grep -Eq "^[\*\+]? +origin/${feat_branch}" <<< "${branchR}") && git push origin --delete "${branch}"
	} done
}
