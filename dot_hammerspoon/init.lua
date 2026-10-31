-- Global hotkeys, the twin of hotkeys.ahk and the GNOME keybindings. Needs
-- Accessibility access (System Settings > Privacy & Security).

hs.autoLaunch(true)

-- Reload whenever chezmoi rewrites this file
configWatcher = hs.pathwatcher.new(hs.configdir, hs.reload):start()

local ctrlAlt = { "ctrl", "alt" }

-- New window of an app: `mods`+`key` if it's running, otherwise launch it
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

-- Ctrl+Alt+E: Finder
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

-- Caps Lock: Mission Control. macOS can't bind Caps Lock, so remap it to F18
-- (HID codes) and bind that. The remap is lost on reboot and macOS can reset
-- it on wake, so it's applied at startup and after waking. Leave Caps Lock
-- alone in System Settings > Keyboard > Modifier Keys, which overwrites it.
local function remapCapsLock()
  hs.execute([[/usr/bin/hidutil property --set '{"UserKeyMapping":[{"HIDKeyboardModifierMappingSrc":0x700000039,"HIDKeyboardModifierMappingDst":0x70000006D}]}']])
end
remapCapsLock()
capsWatcher = hs.caffeinate.watcher.new(function(event)
  if event == hs.caffeinate.watcher.systemDidWake then remapCapsLock() end
end):start()
hs.hotkey.bind({}, "f18", function() hs.spaces.toggleMissionControl() end)

-- Mouse side buttons switch desktops (Ctrl+Left/Right) instead of back/forward.
-- Logi Options+, if installed, grabs these buttons first.
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
