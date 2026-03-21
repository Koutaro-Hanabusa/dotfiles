# Snapshot file
# Unset all aliases to avoid conflicts with functions
unalias -a 2>/dev/null || true
# Functions
__git_eread () {
	test -r "$1" && IFS=$__git_CRLF read -r "$2" < "$1"
}
__git_ps1 () {
	local exit="$?" 
	local pcmode=no 
	local detached=no 
	local ps1pc_start='\u@\h:\w ' 
	local ps1pc_end='\$ ' 
	local printf_format=' (%s)' 
	case "$#" in
		(2 | 3) pcmode=yes 
			ps1pc_start="$1" 
			ps1pc_end="$2" 
			printf_format="${3:-$printf_format}" 
			PS1="$ps1pc_start$ps1pc_end"  ;;
		(0 | 1) printf_format="${1:-$printf_format}"  ;;
		(*) return "$exit" ;;
	esac
	local ps1_expanded=yes 
	[ -z "${ZSH_VERSION-}" ] || eval '[[ -o PROMPT_SUBST ]]' || ps1_expanded=no 
	[ -z "${BASH_VERSION-}" ] || shopt -q promptvars || ps1_expanded=no 
	local repo_info rev_parse_exit_code
	repo_info="$(git rev-parse --git-dir --is-inside-git-dir \
		--is-bare-repository --is-inside-work-tree --show-ref-format \
		--short HEAD 2>/dev/null)" 
	rev_parse_exit_code="$?" 
	if [ -z "$repo_info" ]
	then
		return "$exit"
	fi
	local LF="$__git_LF" 
	local short_sha="" 
	if [ "$rev_parse_exit_code" = "0" ]
	then
		short_sha="${repo_info##*$LF}" 
		repo_info="${repo_info%$LF*}" 
	fi
	local ref_format="${repo_info##*$LF}" 
	repo_info="${repo_info%$LF*}" 
	local inside_worktree="${repo_info##*$LF}" 
	repo_info="${repo_info%$LF*}" 
	local bare_repo="${repo_info##*$LF}" 
	repo_info="${repo_info%$LF*}" 
	local inside_gitdir="${repo_info##*$LF}" 
	local g="${repo_info%$LF*}" 
	if [ "true" = "$inside_worktree" ] && [ -n "${GIT_PS1_HIDE_IF_PWD_IGNORED-}" ] && [ "$(git config --bool bash.hideIfPwdIgnored)" != "false" ] && git check-ignore -q .
	then
		return "$exit"
	fi
	local sparse="" 
	if [ -z "${GIT_PS1_COMPRESSSPARSESTATE-}" ] && [ -z "${GIT_PS1_OMITSPARSESTATE-}" ] && [ "$(git config --bool core.sparseCheckout)" = "true" ]
	then
		sparse="|SPARSE" 
	fi
	local r="" 
	local b="" 
	local step="" 
	local total="" 
	if [ -d "$g/rebase-merge" ]
	then
		__git_eread "$g/rebase-merge/head-name" b
		__git_eread "$g/rebase-merge/msgnum" step
		__git_eread "$g/rebase-merge/end" total
		r="|REBASE" 
	else
		if [ -d "$g/rebase-apply" ]
		then
			__git_eread "$g/rebase-apply/next" step
			__git_eread "$g/rebase-apply/last" total
			if [ -f "$g/rebase-apply/rebasing" ]
			then
				__git_eread "$g/rebase-apply/head-name" b
				r="|REBASE" 
			elif [ -f "$g/rebase-apply/applying" ]
			then
				r="|AM" 
			else
				r="|AM/REBASE" 
			fi
		elif [ -f "$g/MERGE_HEAD" ]
		then
			r="|MERGING" 
		elif __git_sequencer_status
		then
			:
		elif [ -f "$g/BISECT_LOG" ]
		then
			r="|BISECTING" 
		fi
		if [ -n "$b" ]
		then
			:
		elif [ -h "$g/HEAD" ]
		then
			b="$(git symbolic-ref HEAD 2>/dev/null)" 
		else
			local head="" 
			case "$ref_format" in
				(files) if ! __git_eread "$g/HEAD" head
					then
						return "$exit"
					fi
					case $head in
						("ref: "*) head="${head#ref: }"  ;;
						(*) head=""  ;;
					esac ;;
				(*) head="$(git symbolic-ref HEAD 2>/dev/null)"  ;;
			esac
			if test -z "$head"
			then
				detached=yes 
				b="$(
				case "${GIT_PS1_DESCRIBE_STYLE-}" in
				(contains)
					git describe --contains HEAD ;;
				(branch)
					git describe --contains --all HEAD ;;
				(tag)
					git describe --tags HEAD ;;
				(describe)
					git describe HEAD ;;
				(* | default)
					git describe --tags --exact-match HEAD ;;
				esac 2>/dev/null)"  || b="$short_sha..." 
				b="($b)" 
			else
				b="$head" 
			fi
		fi
	fi
	if [ -n "$step" ] && [ -n "$total" ]
	then
		r="$r $step/$total" 
	fi
	local conflict="" 
	if [ "${GIT_PS1_SHOWCONFLICTSTATE-}" = "yes" ] && [ "$(git ls-files --unmerged 2>/dev/null)" ]
	then
		conflict="|CONFLICT" 
	fi
	local w="" 
	local i="" 
	local s="" 
	local u="" 
	local h="" 
	local c="" 
	local p="" 
	local upstream="" 
	if [ "true" = "$inside_gitdir" ]
	then
		if [ "true" = "$bare_repo" ]
		then
			c="BARE:" 
		else
			b="GIT_DIR!" 
		fi
	elif [ "true" = "$inside_worktree" ]
	then
		if [ -n "${GIT_PS1_SHOWDIRTYSTATE-}" ] && [ "$(git config --bool bash.showDirtyState)" != "false" ]
		then
			git diff --no-ext-diff --quiet || w="*" 
			git diff --no-ext-diff --cached --quiet || i="+" 
			if [ -z "$short_sha" ] && [ -z "$i" ]
			then
				i="#" 
			fi
		fi
		if [ -n "${GIT_PS1_SHOWSTASHSTATE-}" ] && git rev-parse --verify --quiet refs/stash > /dev/null
		then
			s="$" 
		fi
		if [ -n "${GIT_PS1_SHOWUNTRACKEDFILES-}" ] && [ "$(git config --bool bash.showUntrackedFiles)" != "false" ] && git ls-files --others --exclude-standard --directory --no-empty-directory --error-unmatch -- ':/*' > /dev/null 2> /dev/null
		then
			u="%${ZSH_VERSION+%}" 
		fi
		if [ -n "${GIT_PS1_COMPRESSSPARSESTATE-}" ] && [ "$(git config --bool core.sparseCheckout)" = "true" ]
		then
			h="?" 
		fi
		if [ -n "${GIT_PS1_SHOWUPSTREAM-}" ]
		then
			__git_ps1_show_upstream
		fi
	fi
	local z="${GIT_PS1_STATESEPARATOR- }" 
	b=${b##refs/heads/} 
	if [ "$pcmode" = yes ] && [ "$ps1_expanded" = yes ]
	then
		__git_ps1_branch_name=$b 
		b="\${__git_ps1_branch_name}" 
	fi
	if [ -n "${GIT_PS1_SHOWCOLORHINTS-}" ]
	then
		__git_ps1_colorize_gitstring
	fi
	local f="$h$w$i$s$u$p" 
	local gitstring="$c$b${f:+$z$f}${sparse}$r${upstream}${conflict}" 
	if [ "$pcmode" = yes ]
	then
		if [ "${__git_printf_supports_v-}" != yes ]
		then
			gitstring=$(printf -- "$printf_format" "$gitstring") 
		else
			printf -v gitstring -- "$printf_format" "$gitstring"
		fi
		PS1="$ps1pc_start$gitstring$ps1pc_end" 
	else
		printf -- "$printf_format" "$gitstring"
	fi
	return "$exit"
}
__git_ps1_colorize_gitstring () {
	if [ -n "${ZSH_VERSION-}" ]
	then
		local c_red='%F{red}' 
		local c_green='%F{green}' 
		local c_lblue='%F{blue}' 
		local c_clear='%f' 
	else
		local c_pre="${GIT_PS1_COLOR_PRE-$__git_SOH}${__git_ESC}[" 
		local c_post="m${GIT_PS1_COLOR_POST-$__git_STX}" 
		local c_red="${c_pre}31${c_post}" 
		local c_green="${c_pre}32${c_post}" 
		local c_lblue="${c_pre}1;34${c_post}" 
		local c_clear="${c_pre}0${c_post}" 
	fi
	local bad_color="$c_red" 
	local ok_color="$c_green" 
	local flags_color="$c_lblue" 
	local branch_color="" 
	if [ "$detached" = no ]
	then
		branch_color="$ok_color" 
	else
		branch_color="$bad_color" 
	fi
	if [ -n "$c" ]
	then
		c="$branch_color$c$c_clear" 
	fi
	b="$branch_color$b$c_clear" 
	if [ -n "$w" ]
	then
		w="$bad_color$w$c_clear" 
	fi
	if [ -n "$i" ]
	then
		i="$ok_color$i$c_clear" 
	fi
	if [ -n "$s" ]
	then
		s="$flags_color$s$c_clear" 
	fi
	if [ -n "$u" ]
	then
		u="$bad_color$u$c_clear" 
	fi
}
__git_ps1_show_upstream () {
	local key value
	local svn_remotes="" svn_url_pattern="" count n 
	local upstream_type=git legacy="" verbose="" name="" 
	local LF="$__git_LF" 
	local output="$(git config -z --get-regexp '^(svn-remote\..*\.url|bash\.showupstream)$' 2>/dev/null | tr '\0\n' '\n ')" 
	while read -r key value
	do
		case "$key" in
			(bash.showupstream) GIT_PS1_SHOWUPSTREAM="$value" 
				if [ -z "${GIT_PS1_SHOWUPSTREAM}" ]
				then
					p="" 
					return
				fi ;;
			(svn-remote.*.url) svn_remotes=${svn_remotes}${value}${LF} 
				svn_url_pattern="$svn_url_pattern\\|$value" 
				upstream_type=svn+git  ;;
		esac
	done <<OUTPUT
$output
OUTPUT
	local option
	for option in ${GIT_PS1_SHOWUPSTREAM-}
	do
		case "$option" in
			(git | svn) upstream_type="$option"  ;;
			(verbose) verbose=1  ;;
			(legacy) legacy=1  ;;
			(name) name=1  ;;
		esac
	done
	case "$upstream_type" in
		(git) upstream_type="@{upstream}"  ;;
		(svn*) local svn_upstream="$(
			git log --first-parent -1 \
				--grep="^git-svn-id: \(${svn_url_pattern#??}\)" 2>/dev/null
		)" 
			if [ -n "$svn_upstream" ]
			then
				svn_upstream=${svn_upstream##*$LF} 
				svn_upstream=${svn_upstream#*: } 
				svn_upstream=${svn_upstream%@*} 
				case ${LF}${svn_remotes} in
					(*"${LF}${svn_upstream}${LF}"*) upstream_type=${GIT_SVN_ID:-git-svn}  ;;
					(*) upstream_type=${svn_upstream#/}  ;;
				esac
			elif [ "svn+git" = "$upstream_type" ]
			then
				upstream_type="@{upstream}" 
			fi ;;
	esac
	if [ -z "$legacy" ]
	then
		count="$(git rev-list --count --left-right \
				"$upstream_type"...HEAD 2>/dev/null)" 
	else
		local commits
		if commits="$(git rev-list --left-right "$upstream_type"...HEAD 2>/dev/null)" 
		then
			local commit behind=0 ahead=0 
			for commit in $commits
			do
				case "$commit" in
					("<"*) behind=$((behind+1))  ;;
					(*) ahead=$((ahead+1))  ;;
				esac
			done
			count="$behind	$ahead" 
		else
			count="" 
		fi
	fi
	if [ -z "$verbose" ]
	then
		case "$count" in
			("") p=""  ;;
			("0	0") p="="  ;;
			("0	"*) p=">"  ;;
			(*"	0") p="<"  ;;
			(*) p="<>"  ;;
		esac
	else
		case "$count" in
			("") upstream=""  ;;
			("0	0") upstream="|u="  ;;
			("0	"*) upstream="|u+${count#0	}"  ;;
			(*"	0") upstream="|u-${count%	0}"  ;;
			(*) upstream="|u+${count#*	}-${count%	*}"  ;;
		esac
		if [ -n "$count" ] && [ -n "$name" ]
		then
			__git_ps1_upstream_name=$(git rev-parse \
				--abbrev-ref "$upstream_type" 2>/dev/null) 
			if [ "$pcmode" = yes ] && [ "$ps1_expanded" = yes ]
			then
				upstream="$upstream \${__git_ps1_upstream_name}" 
			else
				upstream="$upstream ${__git_ps1_upstream_name}" 
				unset __git_ps1_upstream_name
			fi
		fi
	fi
}
__git_sequencer_status () {
	local todo
	if test -f "$g/CHERRY_PICK_HEAD"
	then
		r="|CHERRY-PICKING" 
		return 0
	elif test -f "$g/REVERT_HEAD"
	then
		r="|REVERTING" 
		return 0
	elif __git_eread "$g/sequencer/todo" todo
	then
		case "$todo" in
			(p[\ \	] | pick[\ \	]*) r="|CHERRY-PICKING" 
				return 0 ;;
			(revert[\ \	]*) r="|REVERTING" 
				return 0 ;;
		esac
	fi
	return 1
}
__zoxide_cd () {
	\builtin cd -- "$@"
}
__zoxide_doctor () {
	[[ ${_ZO_DOCTOR:-1} -ne 0 ]] || return 0
	[[ ${chpwd_functions[(Ie)__zoxide_hook]:-} -eq 0 ]] || return 0
	_ZO_DOCTOR=0 
	\builtin printf '%s\n' 'zoxide: detected a possible configuration issue.' 'Please ensure that zoxide is initialized right at the end of your shell configuration file (usually ~/.zshrc).' '' 'If the issue persists, consider filing an issue at:' 'https://github.com/ajeetdsouza/zoxide/issues' '' 'Disable this message by setting _ZO_DOCTOR=0.' '' >&2
}
__zoxide_hook () {
	\command zoxide add -- "$(__zoxide_pwd)"
}
__zoxide_pwd () {
	\builtin pwd -L
}
__zoxide_z () {
	__zoxide_doctor
	if [[ "$#" -eq 0 ]]
	then
		__zoxide_cd ~
	elif [[ "$#" -eq 1 ]] && {
			[[ -d "$1" ]] || [[ "$1" = '-' ]] || [[ "$1" =~ ^[-+][0-9]+$ ]]
		}
	then
		__zoxide_cd "$1"
	elif [[ "$#" -eq 2 ]] && [[ "$1" = "--" ]]
	then
		__zoxide_cd "$2"
	else
		\builtin local result
		result="$(\command zoxide query --exclude "$(__zoxide_pwd)" -- "$@")"  && __zoxide_cd "${result}"
	fi
}
__zoxide_zi () {
	__zoxide_doctor
	\builtin local result
	result="$(\command zoxide query --interactive -- "$@")"  && __zoxide_cd "${result}"
}
add-zsh-hook () {
	emulate -L zsh
	local -a hooktypes
	hooktypes=(chpwd precmd preexec periodic zshaddhistory zshexit zsh_directory_name) 
	local usage="Usage: add-zsh-hook hook function\nValid hooks are:\n  $hooktypes" 
	local opt
	local -a autoopts
	integer del list help
	while getopts "dDhLUzk" opt
	do
		case $opt in
			(d) del=1  ;;
			(D) del=2  ;;
			(h) help=1  ;;
			(L) list=1  ;;
			([Uzk]) autoopts+=(-$opt)  ;;
			(*) return 1 ;;
		esac
	done
	shift $(( OPTIND - 1 ))
	if (( list ))
	then
		typeset -mp "(${1:-${(@j:|:)hooktypes}})_functions"
		return $?
	elif (( help || $# != 2 || ${hooktypes[(I)$1]} == 0 ))
	then
		print -u$(( 2 - help )) $usage
		return $(( 1 - help ))
	fi
	local hook="${1}_functions" 
	local fn="$2" 
	if (( del ))
	then
		if (( ${(P)+hook} ))
		then
			if (( del == 2 ))
			then
				set -A $hook ${(P)hook:#${~fn}}
			else
				set -A $hook ${(P)hook:#$fn}
			fi
			if (( ! ${(P)#hook} ))
			then
				unset $hook
			fi
		fi
	else
		if (( ${(P)+hook} ))
		then
			if (( ${${(P)hook}[(I)$fn]} == 0 ))
			then
				typeset -ga $hook
				set -A $hook ${(P)hook} $fn
			fi
		else
			typeset -ga $hook
			set -A $hook $fn
		fi
		autoload $autoopts -- $fn
	fi
}
cd () {
	__zoxide_z "$@"
}
cdi () {
	__zoxide_zi "$@"
}
command_not_found_handler () {
	if [[ "$1" != "mise" && "$1" != "mise-"* ]] && /opt/homebrew/bin/mise hook-not-found -s zsh -- "$1"
	then
		_mise_hook
		"$@"
	elif [ -n "$(declare -f _command_not_found_handler)" ]
	then
		_command_not_found_handler "$@"
	else
		echo "zsh: command not found: $1" >&2
		return 127
	fi
}
fuck () {
	unfunction fuck
	eval $(thefuck --alias)
	fuck "$@"
}
gco () {
	local branch
	branch=$(command git branch --format='%(refname:short)' | fzf --query="$1" --select-1 --exit-0) 
	if [[ -n "$branch" ]]
	then
		git switch "$branch"
	fi
}
ghq-fzf () {
	local repo
	repo=$(ghq list -p | fzf --preview "eza --icons --git -la {}") 
	if [[ -n "$repo" ]]
	then
		cd "$repo"
		zle accept-line
	else
		zle reset-prompt
	fi
}
ghq-get-cd () {
	ghq get "$@" && cd "$(ghq list -p | fzf --query "${@##*/}" --select-1)"
}
git () {
	command git "$@"
	local exit_code=$? 
	if [[ $exit_code -eq 0 && ( ( "$1" == "checkout" && " $* " == *" -b "* ) || ( "$1" == "switch" && " $* " == *" -c "* ) ) ]]
	then
		local branch
		branch=$(command git symbolic-ref --short HEAD 2>/dev/null) 
		local pattern='^(feature|fix|hotfix|release|chore|refactor|docs|test|ci|perf|build)/[0-9]+-[a-z0-9-]+$' 
		if [[ -n "$branch" && ! "$branch" =~ $pattern ]]
		then
			print -P "\n%F{yellow}⚠️  ブランチ名が推奨パターンに沿っていません: %F{red}$branch%f"
			print -P "   %F{white}推奨: %F{green}<type>/<TICKET番号>-<short-summary>%f"
			print -P "   %F{white}例:   %F{green}feature/55-add-login-page%f"
		fi
	fi
	return $exit_code
}
is-at-least () {
	emulate -L zsh
	local IFS=".-" min_cnt=0 ver_cnt=0 part min_ver version order 
	min_ver=(${=1}) 
	version=(${=2:-$ZSH_VERSION} 0) 
	while (( $min_cnt <= ${#min_ver} ))
	do
		while [[ "$part" != <-> ]]
		do
			(( ++ver_cnt > ${#version} )) && return 0
			if [[ ${version[ver_cnt]} = *[0-9][^0-9]* ]]
			then
				order=(${version[ver_cnt]} ${min_ver[ver_cnt]}) 
				if [[ ${version[ver_cnt]} = <->* ]]
				then
					[[ $order != ${${(On)order}} ]] && return 1
				else
					[[ $order != ${${(O)order}} ]] && return 1
				fi
				[[ $order[1] != $order[2] ]] && return 0
			fi
			part=${version[ver_cnt]##*[^0-9]} 
		done
		while true
		do
			(( ++min_cnt > ${#min_ver} )) && return 0
			[[ ${min_ver[min_cnt]} = <-> ]] && break
		done
		(( part > min_ver[min_cnt] )) && return 0
		(( part < min_ver[min_cnt] )) && return 1
		part='' 
	done
}
mise () {
	local command
	command="${1:-}" 
	if [ "$#" = 0 ]
	then
		command /opt/homebrew/bin/mise
		return
	fi
	shift
	case "$command" in
		(deactivate | shell | sh) if [[ ! " $@ " =~ " --help " ]] && [[ ! " $@ " =~ " -h " ]]
			then
				eval "$(command /opt/homebrew/bin/mise "$command" "$@")"
				return $?
			fi ;;
	esac
	command /opt/homebrew/bin/mise "$command" "$@"
}
nvc () {
	local target="${1:-.}" 
	if [[ -n "$TMUX" ]]
	then
		local split_pane_id
		split_pane_id=$(tmux split-window -h -c "$(pwd)" -p 25 -P -F '#{pane_id}') 
		tmux select-pane -L
		tmux set-option -p allow-passthrough on
		command nvim "$target"
		tmux kill-pane -t "$split_pane_id" 2> /dev/null
		return
	fi
	local session_name="nvc-$$-$RANDOM" 
	tmux new-session -d -s "$session_name" -c "$(pwd)"
	tmux set-option -t "$session_name:1.1" -p allow-passthrough on
	tmux send-keys -t "$session_name" "nvim $target; tmux kill-session -t $session_name" Enter
	tmux split-window -h -t "$session_name" -c "$(pwd)" -p 10
	tmux select-pane -t "$session_name:1.1"
	tmux attach-session -t "$session_name"
}
# Shell Options
setopt nohashdirs
setopt login
setopt promptsubst
# Aliases
alias -- cat=bat
alias -- chrome='open -na "Google Chrome" --args --new-window'
alias -- claude='command claude --mcp-config ~/.claude/mcp.json'
alias -- dothelp='_show_md ~/dotfiles/README.md'
alias -- gg=ghq-get-cd
alias -- grep=rg
alias -- la='eza -a --icons --git'
alias -- ll='eza -la --icons --git'
alias -- ls='eza --icons --git'
alias -- run-help=man
alias -- sail='bash vendor/bin/sail'
alias -- tree='eza --tree --icons'
alias -- vim=nvc
alias -- vimhelp='_show_md ~/.config/nvim/doc/README.md'
alias -- which-command=whence
# Check for rg availability
if ! (unalias rg 2>/dev/null; command -v rg) >/dev/null 2>&1; then
  alias rg='/opt/homebrew/Caskroom/claude-code/2.1.62/claude --ripgrep'
fi
export PATH=/Users/1126buri/.nix-profile/bin\:/nix/var/nix/profiles/default/bin\:/opt/homebrew/bin\:/opt/homebrew/sbin\:/Library/Frameworks/Python.framework/Versions/3.12/bin\:/usr/local/bin\:/System/Cryptexes/App/usr/bin\:/usr/bin\:/bin\:/usr/sbin\:/sbin\:/var/run/com.apple.security.cryptexd/codex.system/bootstrap/usr/local/bin\:/var/run/com.apple.security.cryptexd/codex.system/bootstrap/usr/bin\:/var/run/com.apple.security.cryptexd/codex.system/bootstrap/usr/appleinternal/bin\:/Library/Apple/usr/bin\:/usr/local/go/bin\:/Users/1126buri/.nix-profile/bin\:/nix/var/nix/profiles/default/bin\:/Users/1126buri/go/bin\:/Applications/cmux.app/Contents/Resources/bin
