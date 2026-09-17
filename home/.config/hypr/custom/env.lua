-- Preserve cursor sizing and the Intel-driven display configuration.
hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_SIZE", "24")

-- Use the installed GTK platform integration for Qt application icons.
hl.env("QT_QPA_PLATFORMTHEME", "gtk3")
