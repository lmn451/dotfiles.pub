if status is-interactive
    # Commands to run in interactive sessions can go here
end

set -g fish_user_paths "/usr/local/bin" $fish_user_paths
set -g fish_user_paths "/opt/homebrew/bin" $fish_user_paths
[ -f $HOMEBREW_PREFIX/share/autojump/autojump.fish ]; and source "$HOMEBREW_PREFIX/share/autojump/autojump.fish"

starship init fish | source
sk --shell fish | source
alias ls='eza -la';


set -gx PATH $HOMEBREW_PREFIX/lib/ruby/gems/3.3.0/bin $PATH

# pnpm
set -gx PNPM_HOME "$HOME/Library/pnpm"
if not string match -q -- $PNPM_HOME $PATH
  set -gx PATH "$PNPM_HOME" $PATH
end
# pnpm end

alias c "code -n"

# Added by LM Studio CLI (lms)
set -gx PATH $PATH $HOME/.cache/lm-studio/bin
set -gx XDG_CONFIG_HOME "$HOME/.config"

function y
	set tmp (mktemp -t "yazi-cwd.XXXXXX")
	yazi $argv --cwd-file="$tmp"
	if set cwd (command cat -- "$tmp"); and [ -n "$cwd" ]; and [ "$cwd" != "$PWD" ]
		builtin cd -- "$cwd"
	end
	rm -f -- "$tmp"
end

# Go bin
fish_add_path $HOME/go/bin

function pi
 command pi update --all
 rm -rf ~/.pi/agent/extensions/subagent
 rm -rf ~/.pi/agent/skills/web-fetch
 set -gx SUBAGENT_DEBUG_LOG_DIR ./logs
 set -gx SUBAGENT_CANCEL_SNAPSHOT full
    command pi $argv
end


# Added by Antigravity CLI installer
set -gx PATH "$HOME/.local/bin" $PATH

# >>> agterm agent-status >>>
source "$HOME/.config/agterm/agent-status/shell/integration.fish"
# <<< agterm agent-status <<<

# Local secrets are intentionally stored outside the dotfiles repository.
test -r "$HOME/.config/shell/secrets.fish"; and source "$HOME/.config/shell/secrets.fish"

function git_switch
    set -l branches (git branch --format='%(refname:short)')
    or return
    set -l branch (string join \n $branches | fzf --height 40% --border --prompt 'Select a branch: ')
    or return
    set -l current_root (git rev-parse --show-toplevel)
    or return
    set -l worktree_path (
        git worktree list --porcelain | awk -v selected_branch="refs/heads/$branch" '
            $1 == "worktree" { path = substr($0, 10) }
            $1 == "branch" && $2 == selected_branch { print path; exit }
        '
    )
    if test -n "$worktree_path"; and test "$worktree_path" != "$current_root"
        cd "$worktree_path"; or return
        return
    end
    git switch "$branch"
end
