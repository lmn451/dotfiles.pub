function th --description "Attach tmux to the current directory"
    set project (pwd -P)
    set project_name (basename "$project")
    set project_slug (string replace -ar '[^A-Za-z0-9_-]' '-' -- "$project_name")
    set hash_line (printf '%s' "$project" | /usr/bin/shasum -a 256)
    set project_hash (string split ' ' -- "$hash_line")[1]
    set project_hash (string sub -l 8 -- "$project_hash")
    set session_name "$project_slug-$project_hash"

    if set -q TMUX
        command tmux new-window -c "$project"
        return
    end

    if not command tmux has-session -t "=$session_name" 2>/dev/null
        command tmux new-session -d -s "$session_name" -c "$project" 2>/dev/null
    end

    command tmux has-session -t "=$session_name" 2>/dev/null; or return 1
    command tmux set-option -t "$session_name" @project_name "$project_name"
    command tmux attach-session -t "=$session_name"
end
