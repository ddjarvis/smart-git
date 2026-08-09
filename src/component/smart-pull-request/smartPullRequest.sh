# component: smart-pull-request

function smartPullRequest() {
	local branchA="$1"
	local branchB="$2"
	local dateFormat='%a, %Y-%m-%d %H:%M:%S GMT%z'
	local prettyFormat='### **%s** [%h]  |  %cd%n%b'
	local prTitle="" prDesc="" prBody=""
	
	local ghBase="" ghCompare="" ghLink=""
	local amAction="" amLink="" amPkg=""
	
	prTitle="Merge [${branchB}] to [${branchA}]"
	prDesc="$(
		git log "${branchA}..${branchB}" \
			--date=format:"${dateFormat}" \
			--pretty=format:"${prettyFormat}" |\
			perl -pe 's/(\*\*)\[\d{4}(?:-\d{2}){2}(?:[: ]\d{2}){3}\] /\1/g'
	)"
	printf -v prBody '## %s\n\n%s\n' "${prTitle}" "${prDesc}"
	
	ghBase="$(git remote -v | grep -E "^${remote}.+\(push\)$" | sed -r 's/.+(https.+)\.git.+/\1/')"
	ghCompare="${branchA}...${branchB}"
	ghLink="${ghBase}/compare/${ghCompare}"
	
	amAction="android.intent.action.VIEW"
	amLink="${ghLink}"
	amPkg="com.github.android"
	
	# echo "${prBody}"
	termux-clipboard-set "${prTitle}"
	am start --user 0 -a "${amAction}" -d "${amLink}" "${amPkg}" &>/dev/null
	termux-clipboard-set "${prBody}"
}

# smartPullRequest "dev" "feat/smart-commit"