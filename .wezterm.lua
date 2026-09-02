local wezterm = require("wezterm")
local act = wezterm.action

local config = wezterm.config_builder()
local tmux_bin = "tmux"
local local_shell = { "/bin/zsh", "-l" }
local persistent_tmux = { tmux_bin, "new-session", "-A", "-s", "main" }
local dark_color_scheme = "Gruvbox Dark (Gogh)"
local light_color_scheme = "Gruvbox Light"
local theme_state_file = wezterm.home_dir .. "/.local/share/wezterm/current-theme"
local resurrect_state_dir = wezterm.home_dir .. "/.local/share/wezterm/resurrect"
local tmux_session_picker = "fish "
    .. wezterm.home_dir
    .. "/.config/fish/scripts/tmux-session-picker.fish"
local closed_tabs = {}
local hyperkey_monitor_script = wezterm.home_dir .. "/bin/hyperkey-monitor.sh"

local bar = wezterm.plugin.require("https://github.com/adriankarlen/bar.wezterm")
local resurrect = wezterm.plugin.require("https://github.com/YedPool/Wezurrect")

-- Persist native windows, tabs, splits, and working directories across restarts.
-- Scrollback is intentionally excluded because the state files are plaintext.
resurrect.state_manager.change_state_save_dir(resurrect_state_dir)
resurrect.state_manager.set_max_nlines(0)
resurrect.state_manager.event_driven_save({ save_workspaces = true })
resurrect.state_manager.periodic_save({
    interval_seconds = 60,
    save_workspaces = true,
})

wezterm.on("gui-startup", function()
    local restored = resurrect.state_manager.resurrect_on_gui_startup()
    if not restored then
        wezterm.mux.spawn_window({})
    end
end)

local function foreground_process(pane)
    return pane:get_foreground_process_name() or ""
end

local function write_theme_mode(mode)
    local file, error_message = io.open(theme_state_file, "w")
    if not file then
        wezterm.log_error("theme-selector: cannot write state: ", error_message)
        return false
    end

    file:write(mode, "\n")
    file:close()
    return true
end

local function read_theme_mode()
    local file = io.open(theme_state_file, "r")
    if not file then return "dark" end

    local mode = file:read("*l")
    file:close()
    return mode == "light" and "light" or "dark"
end

local function theme_colors(scheme)
    local colors = wezterm.get_builtin_color_schemes()[scheme]
    if not colors then return nil end

    colors.tab_bar = {
        background = "transparent",
        active_tab = {
            bg_color = "transparent",
            fg_color = colors.ansi[4],
        },
        inactive_tab = {
            bg_color = "transparent",
            fg_color = colors.ansi[6],
        },
    }
    return colors
end

local function apply_color_scheme(window, scheme, mode)
    local selected_colors = theme_colors(scheme)
    if not selected_colors then
        wezterm.log_error("theme-selector: unknown color scheme: ", scheme)
        return
    end

    local overrides = window:get_config_overrides() or {}
    overrides.colors = selected_colors
    overrides.color_scheme = scheme
    window:set_config_overrides(overrides)
    write_theme_mode(mode)
    wezterm.log_info("theme-selector: applied ", scheme)
    window:toast_notification("WezTerm", "Color scheme: " .. scheme, nil, 2000)
end

config.font = wezterm.font_with_fallback({ "PragmataPro Mono Liga" })
config.font_size = 24
config.adjust_window_size_when_changing_font_size = false
config.debug_key_events = false
config.native_macos_fullscreen_mode = false
config.window_decorations = "RESIZE"
local startup_color_scheme = read_theme_mode() == "light" and light_color_scheme or dark_color_scheme
config.color_scheme = startup_color_scheme

-- WezTerm starts locally; tmux is attached explicitly with th or the launch menu.
config.default_prog = local_shell
config.enable_tab_bar = true
config.hide_tab_bar_if_only_one_tab = false
config.use_fancy_tab_bar = false
config.tab_max_width = 32

config.launch_menu = {
    {
        label = "Persistent tmux",
        args = persistent_tmux,
    },
    {
        label = "Local zsh",
        args = local_shell,
    },
    {
        label = "Hyperkey Monitor (tmux)",
        args = {
            tmux_bin,
            "new-session",
            "-A",
            "-s",
            "hyperkey-monitor",
            hyperkey_monitor_script .. " 6",
        },
        cwd = wezterm.home_dir .. "/bin",
    },
}

config.keys = {
    {
        key = "Enter",
        mods = "ALT",
        action = "DisableDefaultAssignment",
    },
    {
        key = "P",
        mods = "CMD|SHIFT",
        action = act.ActivateCommandPalette,
    },
    {
        key = "t",
        mods = "CMD",
        action = act.SpawnTab("CurrentPaneDomain"),
    },
    {
        key = "t",
        mods = "CMD|SHIFT",
        action = wezterm.action_callback(function(window, pane)
            local closed_tab = table.remove(closed_tabs) or {
                cwd = wezterm.home_dir,
                args = local_shell,
            }
            window:perform_action(act.SpawnCommandInNewTab({
                cwd = closed_tab.cwd,
                args = closed_tab.args,
            }), pane)
        end),
    },
    {
        key = "w",
        mods = "CMD",
        action = wezterm.action_callback(function(window, pane)
            local current_dir = pane:get_current_working_dir()
            local process_name = pane:get_foreground_process_name() or ""
            table.insert(closed_tabs, {
                cwd = current_dir and current_dir.file_path or wezterm.home_dir,
                args = process_name:match("tmux$") and persistent_tmux or local_shell,
            })
            if #closed_tabs > 10 then
                table.remove(closed_tabs, 1)
            end
            window:perform_action(act.CloseCurrentTab({ confirm = false }), pane)
        end),
    },
    {
        key = "q",
        mods = "CMD",
        action = wezterm.action_callback(function(window, pane)
            resurrect.state_manager.save_workspace_full()
            window:perform_action(act.QuitApplication, pane)
        end),
    },

    -- tmux uses Ctrl-a as its prefix in ~/.tmux.conf.
    {
        key = "t",
        mods = "CMD|ALT",
        action = wezterm.action_callback(function(window, pane)
            local process_name = foreground_process(pane)
            if process_name:match("tmux$") then
                window:perform_action(act.SendString("\x01c"), pane)
            elseif process_name:match("zsh$") or process_name:match("fish$") then
                window:perform_action(act.SendString("\x15th\r"), pane)
            end
        end),
    },
    {
        key = "s",
        mods = "CMD|ALT",
        action = wezterm.action_callback(function(window, pane)
            local process_name = foreground_process(pane)
            if process_name:match("tmux$") then
                window:perform_action(act.SendString("\x01s"), pane)
            elseif process_name:match("zsh$") or process_name:match("fish$") then
                window:perform_action(act.SendString("\x15" .. tmux_session_picker .. "\r"), pane)
            end
        end),
    },
    {
        key = "LeftArrow",
        mods = "CMD|ALT",
        action = act.SendString("\x01p"),
    },
    {
        key = "RightArrow",
        mods = "CMD|ALT",
        action = act.SendString("\x01n"),
    },
    {
        key = "d",
        mods = "CMD",
        action = act.SplitHorizontal({
            domain = "CurrentPaneDomain",
            args = local_shell,
        }),
    },
    {
        key = "d",
        mods = "CMD|SHIFT",
        action = act.SplitVertical({
            domain = "CurrentPaneDomain",
            args = local_shell,
        }),
    },
    {
        key = "Enter",
        mods = "CMD",
        action = act.SendString("\x01z"),
    },

    -- Shell cursor movement and deletion.
    {
        key = "LeftArrow",
        mods = "ALT",
        action = act.SendString("\x1bb"),
    },
    {
        key = "RightArrow",
        mods = "ALT",
        action = act.SendString("\x1bf"),
    },
    {
        key = "Backspace",
        mods = "ALT",
        action = act.SendString("\x1b\x7f"),
    },
    {
        key = "Backspace",
        mods = "CMD",
        action = act.SendString("\x15"),
    },
    {
        key = "LeftArrow",
        mods = "CMD",
        -- Ctrl-a is tmux's prefix, so send it twice to pass one through.
        action = act.SendString("\x01\x01"),
    },
    {
        key = "RightArrow",
        mods = "CMD",
        action = act.SendString("\x05"),
    },
}

wezterm.on("augment-command-palette", function()
    return {
        {
            brief = "Theme: Gruvbox Dark",
            action = wezterm.action_callback(function(window)
                apply_color_scheme(window, dark_color_scheme, "dark")
            end),
        },
        {
            brief = "Theme: Gruvbox Light",
            action = wezterm.action_callback(function(window)
                apply_color_scheme(window, light_color_scheme, "light")
            end),
        },
    }
end)

if wezterm.gui then
    local search_mode = wezterm.gui.default_key_tables().search_mode or {}
    local copy_mode = wezterm.gui.default_key_tables().copy_mode or {}

    table.insert(search_mode, {
        key = "Escape",
        mods = "NONE",
        action = act.Multiple({ act.CopyMode("Close"), act.CopyMode("Close") }),
    })
    table.insert(copy_mode, {
        key = "Escape",
        mods = "NONE",
        action = act.CopyMode("Close"),
    })

    config.key_tables = {
        search_mode = search_mode,
        copy_mode = copy_mode,
    }
end

if bar and bar.apply_to_config then
    bar.apply_to_config(config)
end

return config
