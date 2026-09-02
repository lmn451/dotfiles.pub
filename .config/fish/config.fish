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
alias gs 'git_switch'

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
    set -l branches branch branch_name current_root selected selected_parts worktree_path
    set current_root (command git rev-parse --show-toplevel)
    or return
    if not command -q fzf
        echo 'git_switch: fzf is required' >&2
        return 1
    end
    set branches (
        command git for-each-ref --format='%(refname:short)' refs/heads/ |
        while read -l branch_name
            set worktree_path (
                command git worktree list --porcelain | awk -v selected_branch="refs/heads/$branch_name" '
                    $1 == "worktree" { path = substr($0, 10) }
                    $1 == "branch" && $2 == selected_branch { print path; exit }
                '
            )
            if test -n "$worktree_path"
                printf '%s\t%s\n' "$branch_name" "$worktree_path"
            else
                printf '%s\t(no worktree)\n' "$branch_name"
            end
        end
    )
    or return
    set selected (string join \n $branches | fzf --height 40% --border --prompt 'Select a branch: ')
    or return
    set selected_parts (string split -m 1 \t -- "$selected")
    set branch $selected_parts[1]
    test -n "$branch"; or return
    set worktree_path (
        command git worktree list --porcelain | awk -v selected_branch="refs/heads/$branch" '
            $1 == "worktree" { path = substr($0, 10) }
            $1 == "branch" && $2 == selected_branch { print path; exit }
        '
    )
    if test -n "$worktree_path"; and test "$worktree_path" != "$current_root"
        cd "$worktree_path"; or return
        return
    end
    command git switch -- "$branch"
end
