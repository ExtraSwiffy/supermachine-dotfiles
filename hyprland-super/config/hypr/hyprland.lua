local home = os.getenv("HOME")
local terminal = "foot"
local main_mod = "SUPER"

hl.monitor({ output = "", mode = "preferred", position = "auto", scale = "auto" })

-- A host may override the fallback monitor rule without changing tracked files.
local monitor_overrides = home .. "/.config/hypr/monitors.lua"
local override_file = io.open(monitor_overrides)
if override_file then
    override_file:close()
    dofile(monitor_overrides)
end

hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_SIZE", "24")

hl.config({
    general = {
        gaps_in = 12,
        gaps_out = 12,
        border_size = 2,
        col = {
            active_border = "rgba(86d9d9ee)",
            inactive_border = "rgba(263238aa)",
        },
        layout = "dwindle",
        resize_on_border = true,
    },
    decoration = {
        rounding = 14,
        rounding_power = 2,
        active_opacity = 1,
        inactive_opacity = 0.96,
        shadow = {
            enabled = true,
            range = 18,
            render_power = 3,
            color = "rgba(00000066)",
        },
        blur = {
            enabled = true,
            size = 7,
            passes = 3,
            new_optimizations = true,
        },
    },
    input = {
        kb_layout = "us",
        follow_mouse = 1,
        touchpad = { natural_scroll = true },
    },
    dwindle = { preserve_split = true },
    misc = {
        force_default_wallpaper = 0,
        disable_hyprland_logo = true,
        disable_splash_rendering = true,
    },
})

hl.curve("smooth", { type = "bezier", points = { { 0.22, 1 }, { 0.36, 1 } } })
hl.animation({ leaf = "windows", enabled = true, speed = 5, bezier = "smooth", style = "popin 85%" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 4, bezier = "smooth", style = "popin 85%" })
hl.animation({ leaf = "workspaces", enabled = true, speed = 5, bezier = "smooth", style = "slide" })

hl.on("hyprland.start", function()
    hl.exec_cmd("qs -c supermachine -d")
    hl.exec_cmd("dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP")
end)

hl.bind(main_mod .. " + Return", hl.dsp.exec_cmd(terminal))
hl.bind(main_mod .. " + Space", hl.dsp.exec_cmd("qs -c supermachine ipc call launcher toggle"))
hl.bind(main_mod .. " + W", hl.dsp.exec_cmd("qs -c supermachine ipc call wallpapers toggle"))
hl.bind(main_mod .. " + Tab", hl.dsp.exec_cmd("qs -c supermachine ipc call controlcenter toggle"))
hl.bind(main_mod .. " + Q", hl.dsp.window.close())
hl.bind(main_mod .. " + F", hl.dsp.window.fullscreen({ mode = "fullscreen" }))
hl.bind(main_mod .. " + V", hl.dsp.window.float({ action = "toggle" }))
hl.bind(main_mod .. " + SHIFT + R", hl.dsp.exec_cmd("qs -c supermachine kill; qs -c supermachine -d"))
hl.bind(main_mod .. " + SHIFT + E", hl.dsp.exit())

hl.bind(main_mod .. " + H", hl.dsp.focus({ direction = "left" }))
hl.bind(main_mod .. " + J", hl.dsp.focus({ direction = "down" }))
hl.bind(main_mod .. " + K", hl.dsp.focus({ direction = "up" }))
hl.bind(main_mod .. " + L", hl.dsp.focus({ direction = "right" }))
hl.bind(main_mod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind(main_mod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

for i = 1, 5 do
    hl.bind(main_mod .. " + " .. i, hl.dsp.focus({ workspace = i }))
    hl.bind(main_mod .. " + SHIFT + " .. i, hl.dsp.window.move({ workspace = i }))
end

hl.window_rule({
    name = "suppress-maximize-events",
    match = { class = ".*" },
    suppress_event = "maximize",
})

hl.layer_rule({
    name = "supermachine-shell-blur",
    match = { namespace = "supermachine.*" },
    blur = true,
    ignore_alpha = 0.2,
})
