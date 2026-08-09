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
		forCommit=0
		forPush=0
		
		(git ls-files --others --exclude-standard -z | grep -qz .) && git add -A .
		
		gitDiff="$(git diff)"
		if [[ "${gitDiff}" == "" ]]; then {
			gitDiff="$(git diff)"
			[[ "${gitDiff}" == "" ]] && gitDiff="$(git diff --staged)"
		} fi
		if [[ "${gitDiff}" != "" ]]; then forCommit=1; fi
		
		forPush="$(git rev-list --count @{upstream}..HEAD 2>/dev/null)"
		
		if (( forCommit == 0 && forPush == 0 )); then {
			echo -e "\e[3;90mNo changes to commit.\e[0m"
			unset -f askYesNo
			return
		} fi
		
		printf '\e[3m%s\e[0m\n' "Generating..."
		response="$(aichat --role "smart-commits" "git diff: ${gitDiff}")"; 
		printf "\r"
	} fi; 
	title="$(echo "$response" | awk '/```title/{flag=1; next} /```/{flag=0} flag')"; 
	description="$(echo "$response" | awk '/```description/{flag=1; next} /```/{flag=0} flag')"; 
	
	printf "\033[1m%s\033[0m\n\n%s\n\n" "${title}" "${description}";
	if (( forCommit > 0 )); then
		if (askYesNo "Commit?"); then commit=1; fi
	fi
	if (( commit > 0 || forPush > 0 )); then
		if (askYesNo "Push Commits?"); then push=1; fi
	fi
	
	if (( commit > 0 || push > 0 )); then {
		branch="$(git branch --show-current)"
		repo="$(git remote -v | grep -E "^${remote}.+\(push\)$" | sed -r 's/.+github\.com\/(.+)\.git.+/\1/')"
		printf '\r\e[2A\e[0J'
	} fi
	if (( commit > 0 )); then { 
		printf 'Processing %s...\n' 'commit(s)'
		if (git s "${title}" "${description}" &>/dev/null); then {
			printf '\r\e[1A\e[0J'
			printf '> Committed changes to branch [%s]: %s\n' "${branch}" "${title}"
		} else {
			printf '\r\e[1A\e[0J'
			printf '\e[31mProcessing %s failed.\e[0m\n' 'commit(s)'
		} fi
	} fi
	if (( push > 0 )); then { 
		printf 'Processing %s...\n' 'push(es)'
		if (git p &>/dev/null); then {
			printf '\r\e[1A\e[0J'
			printf '> Pushed changes from branch [%s] to remote repo: %s\n' "${branch}" "${repo}"
		} else {
			printf '\r\e[1A\e[0J'
			printf '\e[31mProcessing %s failed.\e[0m\n' 'push(es)'
		} fi
	} fi
	unset -f askYesNo;
}