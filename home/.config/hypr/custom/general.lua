-- Input and monitor settings preserved from Caelestia.
hl.config({
    input = {
        kb_layout  = "us,ara",
        kb_options = "grp:alt_shift_toggle",
        follow_mouse = 1,
        sensitivity = 0,
        touchpad = {
            natural_scroll = true,
        },
    },
})

hl.gesture({
    fingers   = 3,
    direction = "horizontal",
    action    = "workspace",
})

hl.device({
    name        = "epic-mouse-v1",
    sensitivity = -0.5,
})

-- Use each connected display's preferred mode. The original dotfiles were
-- hard-coded for the author's 1920x1080 laptop and external monitor.
hl.monitor({ output = "", mode = "preferred", position = "auto", scale = 1 })
