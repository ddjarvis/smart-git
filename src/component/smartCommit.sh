# component: smart-commit

function smartCommit() {
	local CONFIRM_FLAG=""
	if [[ "$1" == "-c" ]] || [[ "$1" == "--confirm" ]]; then CONFIRM_FLAG="--confirm" shift; fi
	
	function askYesNo() {
		local CONFIRM=0
		if [[ "$1" == "-c" ]] || [[ "$1" == "--confirm" ]]; then CONFIRM=1; shift; fi
		if (( $# > 1 )) && [[ "$1" == "" ]]; then shift; fi
	
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
	local gitDiff title description
	if (( $# > 0 )); then { 
		response="$1"; 
	} else {
		gitDiff="$(git diff)";
		if [[ "${gitDiff}" == "" ]]; then { echo "No changes to commit."; unset -f askYesNo; return; } fi
		printf "Generating..."
		response="$(aichat --role "smart-commits" "git diff: ${gitDiff}")"; 
		printf "\r"
	} fi; 
	title="$(echo "$response" | awk '/```title/{flag=1; next} /```/{flag=0} flag')"; 
	description="$(echo "$response" | awk '/```description/{flag=1; next} /```/{flag=0} flag')"; 
	
	printf "\033[1m%s\033[0m\n\n%s\n\n" "${title}" "${description}";
	if (askYesNo "${CONFIRM_FLAG}" "Commit?"); then {
		commit=1
		if (askYesNo "${CONFIRM_FLAG}" "Push Commits?"); then push=1; fi
	} fi
	
	if (( commit > 0 && push > 0 )); then { 
		git sp "${title}" "${description}"; 
	} elif (( commit > 0 )); then { 
		git s "${title}" "${description}"; 
	} fi;
	unset -f askYesNo;
}