# component: smart-commit

function smartCommit() {
	function askYesNo() {
		local question="${1:-Yes or No?}"
		local tmp ret=0
		printf "\n\n\033[2A"
		while :; do { 
			printf '%s (Y/n) ' "${question}"
			read -rst 0.1; 
			read -rsn1; 
			printf '\r\033[0J%s ' "${question}"
			case "${REPLY}" in 
				[Yy])
					ret=0
					printf '%b%s\033[0m\n' "\033[32m" "Yes"; 
					break; 
					;; 
				[Nn])
					ret=1
					printf '%b%s\033[0m\n' "\033[31m" "No"; 
					break; 
					;; 
				*)
					printf '%b%s\033[0m\n' "\033[33m" "Invalid Response!"; 
					while :; do {
						tmp=0
						read -rst 1; tmp=$?; if (( tmp != 0 )); then break; fi
						read -rst 1; tmp=$?; if (( tmp != 0 )); then break; fi
					} done
					printf "\r\e[1A\e[0J"; 
					;; 
			esac; 
		} done; 
		return "${ret}"
	}
	
	local response;
	local commit=0
	local push=0
	local gitDiff="" title="" description=""
	local remote="origin" branch="" repo=""
	
	if (( $# > 0 )); then { 
		response="$1"; 
	} else {
		untracked=0
		staged=0
		
		(grep -q "Untracked files:" <<< "$(git status)") && git add -A .
		
		gitDiff="$(git diff)"
		if [[ "${gitDiff}" == "" ]]; then {
			gitDiff="$(git diff)"
			[[ "${gitDiff}" == "" ]] && gitDiff="$(git diff --staged)"
		} fi
		if [[ "${gitDiff}" == "" ]]; then { echo -e "\e[3;90mNo changes to commit.\e[0m"; unset -f askYesNo; return; } fi
		printf "Generating..."
		response="$(aichat --role "smart-commits" "git diff: ${gitDiff}")"; 
		printf "\r"
	} fi; 
	title="$(echo "$response" | awk '/```title/{flag=1; next} /```/{flag=0} flag')"; 
	description="$(echo "$response" | awk '/```description/{flag=1; next} /```/{flag=0} flag')"; 
	
	printf "\033[1m%s\033[0m\n\n%s\n\n" "${title}" "${description}";
	if (askYesNo "Commit?"); then {
		commit=1
		if (askYesNo "Push Commits?"); then push=1; fi
	} fi
	
	if (( commit > 0 || push > 0 )); then {
		branch="$(git branch --show-current)"
		repo="$(git remote -v | grep -E "^${remote}.+\(push\)$" | sed -r 's/.+github\.com\/(.+)\.git.+/\1/')"
		printf '\r\e[3A\e[0J'
	} fi
	if (( commit > 0 && push > 0 )); then { 
		printf 'Processing %s...\n' 'commit and push'
		git sp "${title}" "${description}" &>/dev/null && {
			printf '\r\e[1A\e[0J'
			printf '> Committed changes to branch [%s]: %s\n' "${branch}" "${title}"
			printf '> Pushing changes from branch [%s] to remote repo: %s\n' "${branch}" "${repo}"
		}
	} elif (( commit > 0 )); then { 
		printf 'Processing %s...\n' 'commit'
		git s "${title}" "${description}" &>/dev/null && {
			printf '\r\e[1A\e[0J'
			printf '> Committed changes to branch [%s]: %s\n' "${branch}" "${title}"
		}
	} fi
	unset -f askYesNo;
}