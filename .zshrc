# ===================================================================
# 1. ZINIT BOOTSTRAP (High-Performance Plugin Manager)
# ===================================================================
if [[ ! -f $HOME/.zinit/bin/zinit.zsh ]]; then
    print -P "%F{33}▓▒░ %F{220}Installing Zinit (zdharma-continuum)...%f"
    command mkdir -p "$HOME/.zinit" && command chmod g-rwX "$HOME/.zinit"
    command git clone https://github.com/zdharma-continuum/zinit.git "$HOME/.zinit/bin" && \
        print -P "%F{33}▓▒░ %F{34}Installation successful.%f" || \
        print -P "%F{160}▓▒░ The clone failed.%f"
fi

source "$HOME/.zinit/bin/zinit.zsh"
autoload -Uz _zinit
(( ${+_comps} )) && _comps[zinit]=_zinit

# ===================================================================
# 2. ENVIRONMENT & PATH CONFIGURATION
# ===================================================================
export EDITOR='zed-preview --wait'
export VISUAL="$EDITOR"
export LANG=en_US.UTF-8

# Base Paths
export PATH="$HOME/bin:/usr/local/bin:$PATH"

# Package Managers & Runtimes
export PNPM_HOME="$HOME/Library/pnpm"
export BUN_INSTALL="$HOME/.bun"
export DENO_INSTALL="$HOME/.deno"
export PATH="$PNPM_HOME/bin:$PNPM_HOME:$BUN_INSTALL/bin:$DENO_INSTALL/bin:$PATH"

# Restored Development Environments (Go, Ruby, Antigravity)
export PATH="$HOME/go/bin:$PATH"
export PATH="$HOMEBREW_PREFIX/lib/ruby/gems/3.3.0/bin:$PATH"
export PATH="$HOME/.antigravity/antigravity/bin:$PATH"

# AI & IDE Tools
export PATH="$PATH:$HOME/.cache/lm-studio/bin"
export PATH="$HOME/.codeium/windsurf/bin:$PATH"

# ===================================================================
# 3. THE "FISH" EXPERIENCE (Zinit Turbo Mode)
# ===================================================================
# Load completions from Homebrew (Optimized: No subshell)
if type brew &>/dev/null; then
    FPATH=$(brew --prefix)/share/zsh-completions:$FPATH
fi
# Initialize the Zsh Completion Engine once, after completion paths are ready.
autoload -Uz compinit
compinit

# Fast Syntax Highlighting & Autosuggestions loaded asynchronously
zinit wait lucid for \
    atinit"ZINIT[COMPLISTERS]='zsh-users/zsh-completions'" \
    zdharma-continuum/fast-syntax-highlighting \
    zsh-users/zsh-autosuggestions \
    Aloxaf/fzf-tab

zinit snippet OMZ::plugins/fzf/fzf.plugin.zsh

# Load OMZ libraries without the bloat
zinit snippet OMZ::lib/git.zsh
zinit snippet OMZ::lib/completion.zsh
zinit snippet OMZ::lib/history.zsh

# ===================================================================
# 4. SHELL OPTIONS & ALIASES
# ===================================================================
setopt share_history
setopt correct
setopt interactivecomments
HIST_STAMPS="dd.mm.yyyy"
ZSH_AUTOSUGGEST_STRATEGY=(history completion)

alias c='code -n'
alias k='kubectl'
alias h='helm'

# ===================================================================
# 5. CUSTOM FUNCTIONS (Restored Workflows)
# ===================================================================
function y() {
	local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
	yazi "$@" --cwd-file="$tmp"
	if cwd="$(command cat -- "$tmp")" && [ -n "$cwd" ] &&[ "$cwd" != "$PWD" ]; then
		builtin cd -- "$cwd"
	fi
	rm -f -- "$tmp"
}

function th() {
    local project="${PWD:A}"
    local project_name="${project:t}"
    local project_slug="${project_name//[^A-Za-z0-9_-]/-}"
    local hash_line project_hash session_name

    hash_line="$(printf '%s' "$project" | /usr/bin/shasum -a 256)" || return 1
    project_hash="${hash_line%% *}"
    project_hash="${project_hash[1,8]}"
    session_name="${project_slug}-${project_hash}"

    if [[ -n "$TMUX" ]]; then
        command tmux new-window -c "$project"
        return
    fi

    if ! command tmux has-session -t "=$session_name" 2>/dev/null; then
        command tmux new-session -d -s "$session_name" -c "$project" 2>/dev/null
    fi

    command tmux has-session -t "=$session_name" 2>/dev/null || return 1
    command tmux set-option -t "$session_name" @project_name "$project_name"
    command tmux attach-session -t "=$session_name"
}

link_mcp() {
    local SOURCE_FILE=~/mcp.json
    local SYMLINK_NAME=./mcp.json
    if [[ -f "$SOURCE_FILE" ]]; then
        if [[ -e "$SYMLINK_NAME" ]]; then
            echo "Error: A file named 'mcp.json' already exists in this directory."
            return 1
        fi
        ln -s "$SOURCE_FILE" "$SYMLINK_NAME"
        echo "Symlink 'mcp.json' created for '$SOURCE_FILE'."
    else
        echo "Error: Source file '$SOURCE_FILE' does not exist."
        return 1
    fi
}

pi() {
    export SUBAGENT_DEBUG_LOG_DIR=./logs
    export SUBAGENT_CANCEL_SNAPSHOT=full
    command pi update --all
    rm -rf ~/.pi/agent/extensions/subagent
    rm -rf ~/.pi/agent/skills/web-fetch
    command pi "$@"
}

git_switch() {
    local branches branch current_root worktree_path
    branches=$(git branch --format='%(refname:short)') || return
    branch=$(printf '%s\n' "$branches" | fzf --height 40% --border --prompt 'Select a branch: ') || return
    current_root=$(git rev-parse --show-toplevel) || return
    worktree_path=$(
        git worktree list --porcelain | awk -v selected_branch="refs/heads/$branch" '
            $1 == "worktree" { path = substr($0, 10) }
            $1 == "branch" && $2 == selected_branch { print path; exit }
        '
    )
    if [[ -n "$worktree_path" && "$worktree_path" != "$current_root" ]]; then
        cd "$worktree_path" || return
        return
    fi
    git switch "$branch"
}


# ===================================================================
# 6. FINAL INITIALIZATIONS (Evals & Sourcing)
# ===================================================================
# Initialize Starship (The Rust-powered prompt)
eval "$(starship init zsh)"

# Initialize the Node version manager.
eval "$(fnm env --use-on-cd)"

# Initialize FZF & Skim
source <(sk --shell zsh)

# Initialize Autojump (Optimized: No subshell)
[ -f "$HOMEBREW_PREFIX/etc/profile.d/autojump.sh" ] && . "$HOMEBREW_PREFIX/etc/profile.d/autojump.sh"

# Initialize Deno & Bun Completions
[ -f "$HOME/.deno/env" ] && . "$HOME/.deno/env"
[ -s "$HOME/.bun/_bun" ] && source "$HOME/.bun/_bun"
#compdef opencode
###-begin-opencode-completions-###
#
# yargs command completion script
#
# Installation: opencode completion >> ~/.zshrc
#    or opencode completion >> ~/.zprofile on OSX.
#
_opencode_yargs_completions()
{
  local reply
  local si=$IFS
  IFS=$'
' reply=($(COMP_CWORD="$((CURRENT-1))" COMP_LINE="$BUFFER" COMP_POINT="$CURSOR" opencode --get-yargs-completions "${words[@]}"))
  IFS=$si
  if [[ ${#reply} -gt 0 ]]; then
    _describe 'values' reply
  else
    _default
  fi
}
if [[ "'${zsh_eval_context[-1]}" == "loadautofunc" ]]; then
  _opencode_yargs_completions "$@"
else
  compdef _opencode_yargs_completions opencode
fi
###-end-opencode-completions-###


# Added by Antigravity CLI installer
export PATH="$HOME/.local/bin:$PATH"

# >>> agterm agent-status >>>
source $HOME/.config/agterm/agent-status/shell/integration.sh
# <<< agterm agent-status <<<

# Added by LM Studio CLI (lms)
export PATH="$PATH:$HOME/.cache/lm-studio/bin"
# End of LM Studio CLI section

# Local secrets are intentionally stored outside the dotfiles repository.
[[ -r "$HOME/.config/shell/secrets.zsh" ]] && source "$HOME/.config/shell/secrets.zsh"
