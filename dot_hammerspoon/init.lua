-- Global hotkeys for macOS - the twin of hotkeys.ahk on Windows and the GNOME
-- custom keybindings in dconf/settings-daemon.ini, on the same Ctrl+Alt chords
-- (Ctrl+Option here). Hammerspoon needs Accessibility access for any of this:
-- System Settings > Privacy & Security > Accessibility.
--
-- The quake terminal isn't here: iTerm2's hotkey window owns it (Cmd+\, in
-- Library/Application Support/iTerm2/DynamicProfiles/dotfiles.json).

hs.autoLaunch(true)

-- Reload whenever chezmoi rewrites this file, so `chezmoi apply` is enough
configWatcher = hs.pathwatcher.new(hs.configdir, hs.reload):start()

local ctrlAlt = { "ctrl", "alt" }

-- Opens a new window of an app: Cmd+N (or whatever `mods`/`key` says) if it's
-- already running, otherwise a plain launch, which opens one by itself. Running
-- the app's binary again instead would start a second copy, not a new window.
local function newWindow(bundleID, mods, key, launchArgs)
  return function()
    local app = hs.application.get(bundleID)
    if app then
      app:activate()
      hs.eventtap.keyStroke(mods, key, 0, app)
    else
      local args = { "-b", bundleID }
      if launchArgs then
        table.insert(args, "--args")
        for _, a in ipairs(launchArgs) do table.insert(args, a) end
      end
      hs.task.new("/usr/bin/open", nil, args):start()
    end
  end
end

-- Ctrl+Alt+B: browser, Ctrl+Alt+Shift+B: private browser
hs.hotkey.bind(ctrlAlt, "b", newWindow("org.mozilla.firefox", { "cmd" }, "n"))
hs.hotkey.bind({ "ctrl", "alt", "shift" }, "b",
  newWindow("org.mozilla.firefox", { "cmd", "shift" }, "p", { "--private-window" }))

-- Ctrl+Alt+T: terminal (iTerm2)
hs.hotkey.bind(ctrlAlt, "t", newWindow("com.googlecode.iterm2", { "cmd" }, "n"))

-- Ctrl+Alt+E: file manager (Finder - always running, so always Cmd+N; new
-- windows open in ~, see the Finder defaults in run_onchange_after_40)
hs.hotkey.bind(ctrlAlt, "e", newWindow("com.apple.finder", { "cmd" }, "n"))

-- Ctrl+Shift+Esc: system monitor
hs.hotkey.bind({ "ctrl", "shift" }, "escape", function()
  hs.application.launchOrFocusByBundleID("com.apple.ActivityMonitor")
end)

-- Ctrl+Alt+Backspace: close the focused window
hs.hotkey.bind(ctrlAlt, "delete", function()
  local win = hs.window.focusedWindow()
  if win then win:close() end
end)

-- Caps Lock: Mission Control, like Caps -> Super (Activities) on GNOME and
-- Caps -> Win+Tab on Windows. macOS can't bind Caps Lock itself, so the
-- capslock LaunchAgent remaps it to F18 at login and this binds F18.
hs.hotkey.bind({}, "f18", function() hs.spaces.toggleMissionControl() end)

-- Mouse side buttons: back/forward switch desktops (Ctrl+Left/Right, macOS's own
-- Spaces shortcuts), as input-remapper does on Linux and XButton1/2 on
-- Windows. Swallowed, so browsers no longer see them as back/forward. Logi
-- Options+, if installed, grabs these buttons first and this never fires.
sideButtons = hs.eventtap.new({ hs.eventtap.event.types.otherMouseDown }, function(event)
  local button = event:getProperty(hs.eventtap.event.properties.mouseEventButtonNumber)
  if button == 3 then
    hs.eventtap.keyStroke({ "ctrl" }, "left", 0)
    return true
  elseif button == 4 then
    hs.eventtap.keyStroke({ "ctrl" }, "right", 0)
    return true
  end
  return false
end):start()

hs.alert.show("Hotkeys loaded")
