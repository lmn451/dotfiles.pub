#!/opt/homebrew/bin/fish

set -l tmux_bin /opt/homebrew/bin/tmux
set -l fzf_bin /opt/homebrew/bin/fzf

function preview_session --argument-names tmux_bin session
    printf 'WINDOWS\n'
    $tmux_bin list-windows -t "=$session" \
        -F '#{?window_active,>, } #{window_index}:#{window_name}  #{window_panes} panes  #{pane_current_path}'

    printf '\nACTIVE PANE\n'
    $tmux_bin capture-pane -ep -t "=$session:" | /usr/bin/tail -n 35
end

function list_sessions --argument-names tmux_bin
    $tmux_bin list-sessions \
        -F '#{session_name}|#{?@project_name,#{@project_name},#{session_name}}  #{session_windows} windows  #{?session_attached,attached,detached}  #{session_path}'
end

if test (count $argv) -eq 2; and test "$argv[1]" = --preview
    preview_session $tmux_bin "$argv[2]"
    exit 0
end

if test (count $argv) -eq 1; and test "$argv[1]" = --list
    list_sessions $tmux_bin
    exit 0
end

if test (count $argv) -eq 2; and test "$argv[1]" = --kill
    $tmux_bin kill-session -t "=$argv[2]"
    exit $status
end

if not $tmux_bin list-sessions >/dev/null 2>&1
    printf 'No tmux sessions are running.\n' >&2
    exit 1
end

set -l script_path (status filename)
set -l selected (
    list_sessions $tmux_bin |
    $fzf_bin \
        --ansi \
        --border=rounded \
        --border-label=' tmux sessions ' \
        --color='bg+:#3c3836,fg:#ebdbb2,fg+:#fbf1c7,border:#665c54,label:#fabd2f,prompt:#fe8019,pointer:#b8bb26,marker:#83a598,header:#a89984' \
        --cycle \
        --delimiter='|' \
        --bind="ctrl-k:execute-silent(/opt/homebrew/bin/fish '$script_path' --kill {1})+reload(/opt/homebrew/bin/fish '$script_path' --list)" \
        --header='enter: attach   ctrl-k: kill   esc: cancel' \
        --info=inline-right \
        --layout=reverse \
        --margin=1 \
        --no-multi \
        --padding=1,2 \
        --pointer='>' \
        --preview="/opt/homebrew/bin/fish '$script_path' --preview {1}" \
        --preview-label=' session preview ' \
        --preview-window='right,55%,border-left' \
        --prompt='attach> ' \
        --nth=1,2 \
        --with-nth=2
)

test -n "$selected"; or exit 0

set -l session (string split -m 1 '|' -- "$selected")[1]
exec $tmux_bin attach-session -t "=$session"
