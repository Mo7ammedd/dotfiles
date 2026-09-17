-- Preserved from the pre-migration ~/.config/hypr/configs/keybinds.lua.
-- Do not also load hyprland.keybinds: its defaults collide with these chords.

local home = os.getenv("HOME")

local terminal    = "kitty"
local fileManager = "thunar"
local browser     = "zen-browser"
local editor      = "code"

local mainMod = "SUPER"

-- Original chords preserved; shell actions now target end-4 / illogical-impulse.
local function ii(action)
    return hl.dsp.exec_cmd("qs -c ii ipc call " .. action)
end

-- Desktop shell
hl.bind(mainMod .. " + Slash", ii("cheatsheet toggle"), { description = "Shell: Show keybinding sheet" })
hl.bind(mainMod .. " + D",         ii("overlay toggle"), { description = "Shell: Toggle desktop widgets" })
hl.bind(mainMod .. " + K",         ii("preservedShortcuts showAll"), { description = "Shell: Toggle combined panels" })
hl.bind(mainMod .. " + N",         ii("sidebarRight toggle"), { description = "Shell: Toggle notifications and quick settings" })
hl.bind(mainMod .. " + A",         ii("search toggle"), { description = "Shell: Toggle launcher" })
hl.bind(mainMod .. " + SPACE",     ii("search toggle"), { description = "Shell: Toggle launcher" })
hl.bind(mainMod .. " + SUPER_L",   ii("search toggle"), { release = true, description = "Shell: Toggle launcher" })
hl.bind("CTRL + ALT + C",          ii("preservedShortcuts clearNotifications"), { description = "Notifications: Clear notifications" })
hl.bind("PRINT",                   hl.dsp.exec_cmd('hyprshot -m region -o "$(xdg-user-dir PICTURES)/Screenshots"'), { description = "Screenshots: Save selected region" })
hl.bind("SHIFT + PRINT",           hl.dsp.exec_cmd('hyprshot -m region --freeze -o "$(xdg-user-dir PICTURES)/Screenshots"'), { description = "Screenshots: Freeze and save selected region" })
hl.bind("CTRL + PRINT",            hl.dsp.exec_cmd("hyprshot -m region --clipboard-only"), { description = "Screenshots: Copy selected region" })
hl.bind("CTRL + SHIFT + PRINT",    hl.dsp.exec_cmd("hyprshot -m region --freeze --clipboard-only"), { description = "Screenshots: Freeze and copy selected region" })
hl.bind(mainMod .. " + PRINT",     hl.dsp.exec_cmd("hyprshot -m window"), { description = "Screenshots: Capture a window" })

-- Apps
hl.bind(mainMod .. " + T", hl.dsp.exec_cmd(terminal), { description = "Apps: Open terminal" })
hl.bind(mainMod .. " + RETURN", hl.dsp.exec_cmd(terminal), { description = "Apps: Open terminal" })
hl.bind(mainMod .. " + E", hl.dsp.exec_cmd(fileManager), { description = "Apps: Open file manager" })
hl.bind(mainMod .. " + W", ii("wallpaperSelector toggle"), { description = "Wallpaper: Open wallpaper selector" })
hl.bind(mainMod .. " + SHIFT + W", hl.dsp.exec_cmd(browser), { description = "Apps: Open browser" })
hl.bind(mainMod .. " + C", hl.dsp.exec_cmd(editor), { description = "Apps: Open code editor" })
hl.bind(mainMod .. " + V", ii("search clipboardToggle"), { description = "Shell: Open clipboard history" })
hl.bind(mainMod .. " + L", hl.dsp.exec_cmd("qs -c ii ipc call lock activate || hyprlock"), { description = "Session: Lock screen" })
hl.bind(mainMod .. " + R", hl.dsp.exec_cmd(home .. "/.config/hypr/custom/scripts/random-wallpaper.sh"), { description = "Wallpaper: Choose random wallpaper" })
hl.bind(mainMod .. " + SHIFT + N", hl.dsp.exec_cmd(home .. "/.config/hypr/scripts/night-light.sh"), { description = "Display: Toggle night light" })
hl.bind(mainMod .. " + SHIFT + C", hl.dsp.exec_cmd("hyprpicker --autocopy --format=hex --notify"), { description = "Display: Pick and copy a color" })

-- Window management
hl.bind(mainMod .. " + Q", hl.dsp.window.close(), { description = "Windows: Close window" })
hl.bind(mainMod .. " + M", hl.dsp.exit(), { description = "Session: Log out of Hyprland" })
hl.bind(mainMod .. " + F", hl.dsp.window.float({ action = "toggle" }), { description = "Windows: Toggle floating" })
hl.bind(mainMod .. " + SHIFT + F", hl.dsp.window.fullscreen({ mode = "fullscreen", action = "toggle" }), { description = "Windows: Toggle fullscreen" })
hl.bind(mainMod .. " + P", hl.dsp.window.pin({ action = "toggle" }), { description = "Windows: Toggle pin" })
hl.bind(mainMod .. " + G", hl.dsp.group.toggle(), { description = "Windows: Toggle window group" })
hl.bind(mainMod .. " + SHIFT + G", hl.dsp.window.move({ out_of_group = true }), { description = "Windows: Remove window from group" })
hl.bind(mainMod .. " + J", hl.dsp.layout("togglesplit"), { description = "Windows: Toggle split direction" })
hl.bind(mainMod .. " + ALT + SPACE", hl.dsp.window.float({ action = "toggle" }), { description = "Windows: Toggle floating" })

-- Resize
hl.bind(mainMod .. " + Equal",      hl.dsp.window.resize({ x = 10, y = 0 }),  { repeating = true, description = "Resize: Increase width" })
hl.bind(mainMod .. " + Minus",      hl.dsp.window.resize({ x = -10, y = 0 }), { repeating = true, description = "Resize: Decrease width" })
hl.bind(mainMod .. " + SHIFT + Equal", hl.dsp.window.resize({ x = 0, y = 10 }),  { repeating = true, description = "Resize: Increase height" })
hl.bind(mainMod .. " + SHIFT + Minus", hl.dsp.window.resize({ x = 0, y = -10 }), { repeating = true, description = "Resize: Decrease height" })

-- Movement
hl.bind(mainMod .. " + left",  hl.dsp.focus({ direction = "left" }), { description = "Movement: Focus left" })
hl.bind(mainMod .. " + right", hl.dsp.focus({ direction = "right" }), { description = "Movement: Focus right" })
hl.bind(mainMod .. " + up",    hl.dsp.focus({ direction = "up" }), { description = "Movement: Focus up" })
hl.bind(mainMod .. " + down",  hl.dsp.focus({ direction = "down" }), { description = "Movement: Focus down" })

hl.bind(mainMod .. " + CTRL + left",  hl.dsp.window.move({ direction = "left",  group_aware = true }), { description = "Movement: Move window left" })
hl.bind(mainMod .. " + CTRL + right", hl.dsp.window.move({ direction = "right", group_aware = true }), { description = "Movement: Move window right" })
hl.bind(mainMod .. " + CTRL + up",    hl.dsp.window.move({ direction = "up",    group_aware = true }), { description = "Movement: Move window up" })
hl.bind(mainMod .. " + CTRL + down",  hl.dsp.window.move({ direction = "down",  group_aware = true }), { description = "Movement: Move window down" })

for i = 1, 10 do
    local key = i % 10
    hl.bind(mainMod .. " + " .. key,         hl.dsp.focus({ workspace = i }), { description = "Workspaces: Switch to workspace " .. i })
    hl.bind(mainMod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }), { description = "Workspaces: Move window to workspace " .. i })
end

hl.bind(mainMod .. " + Tab", hl.dsp.focus({ workspace = "previous" }), { description = "Workspaces: Return to previous workspace" })

hl.bind(mainMod .. " + ALT + left",  hl.dsp.focus({ workspace = "-1" }), { description = "Workspaces: Previous workspace" })
hl.bind(mainMod .. " + ALT + right", hl.dsp.focus({ workspace = "+1" }), { description = "Workspaces: Next workspace" })

hl.bind(mainMod .. " + SHIFT + left",  hl.dsp.window.move({ workspace = "-1" }), { description = "Workspaces: Move window to previous workspace" })
hl.bind(mainMod .. " + SHIFT + right", hl.dsp.window.move({ workspace = "+1" }), { description = "Workspaces: Move window to next workspace" })

hl.bind(mainMod .. " + S",         hl.dsp.workspace.toggle_special("magic"), { description = "Workspaces: Toggle scratchpad" })
hl.bind(mainMod .. " + SHIFT + S", hl.dsp.window.move({ workspace = "special:magic" }), { description = "Workspaces: Move window to scratchpad" })

hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }), { description = "Workspaces: Next workspace" })
hl.bind(mainMod .. " + mouse_up",   hl.dsp.focus({ workspace = "e-1" }), { description = "Workspaces: Previous workspace" })

hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(),   { mouse = true, description = "Mouse: Drag window" })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true, description = "Mouse: Resize window" })

-- Media / audio / brightness
hl.bind("XF86AudioRaiseVolume",  hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+"),  { locked = true, repeating = true, description = "Media: Increase volume" })
hl.bind("XF86AudioLowerVolume",  hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"),  { locked = true, repeating = true, description = "Media: Decrease volume" })
hl.bind("XF86AudioMute",         hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"), { locked = true, repeating = true, description = "Media: Toggle speaker mute" })
hl.bind("XF86AudioMicMute",      hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"), { locked = true, repeating = true, description = "Media: Toggle microphone mute" })
hl.bind("XF86AudioPlay",         hl.dsp.exec_cmd("playerctl play-pause"), { locked = true, description = "Media: Play or pause" })
hl.bind("XF86AudioPause",        hl.dsp.exec_cmd("playerctl pause"),      { locked = true, description = "Media: Pause" })
hl.bind("XF86AudioNext",         hl.dsp.exec_cmd("playerctl next"),       { locked = true, description = "Media: Next track" })
hl.bind("XF86AudioPrev",         hl.dsp.exec_cmd("playerctl previous"),   { locked = true, description = "Media: Previous track" })
hl.bind("XF86AudioStop",         hl.dsp.exec_cmd("playerctl stop"),       { locked = true, description = "Media: Stop playback" })
hl.bind("XF86MonBrightnessUp",   hl.dsp.exec_cmd("brightnessctl s 5%+"),  { locked = true, repeating = true, description = "Display: Increase brightness" })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl s 5%-"),  { locked = true, repeating = true, description = "Display: Decrease brightness" })
