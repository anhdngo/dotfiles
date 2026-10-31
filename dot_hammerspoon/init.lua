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

-- Key remaps, as HID usage codes. hidutil --set replaces the whole mapping,
-- including what System Settings > Keyboard > Modifier Keys applied, so every
-- remap lives here and that pane stays untouched (changing it wipes these
-- until the next wake or reload). The remap is lost on reboot and macOS can
-- reset it on wake, so it's applied at startup and after waking.
--   Caps Lock -> F18, which Hammerspoon can bind (macOS can't bind Caps Lock)
--   Globe/fn <-> Control
local keyRemaps = {
  { 0x700000039, 0x70000006D },   -- Caps Lock -> F18
  { 0xFF00000003, 0x7000000E4 },  -- fn (external keyboards) -> Right Control
  { 0xFF0100000003, 0x7000000E0 }, -- Globe (built-in keyboard) -> Left Control
  { 0x7000000E0, 0xFF00000003 },  -- Left Control -> fn
  { 0x7000000E4, 0xFF00000003 },  -- Right Control -> fn
}
local function remapKeys()
  local entries = {}
  for _, m in ipairs(keyRemaps) do
    table.insert(entries, string.format(
      '{"HIDKeyboardModifierMappingSrc":0x%X,"HIDKeyboardModifierMappingDst":0x%X}', m[1], m[2]))
  end
  hs.execute("/usr/bin/hidutil property --set '{\"UserKeyMapping\":[" .. table.concat(entries, ",") .. "]}'")
end
remapKeys()
remapWatcher = hs.caffeinate.watcher.new(function(event)
  if event == hs.caffeinate.watcher.systemDidWake then remapKeys() end
end):start()

-- Caps Lock (F18) is a hyper key: hold it and press a letter for the hotkeys
-- below; tap it alone for Mission Control.
hyper = hs.hotkey.modal.new()
hs.hotkey.bind({}, "f18",
  function() hyper.used = false; hyper:enter() end,
  function()
    hyper:exit()
    if not hyper.used then hs.spaces.toggleMissionControl() end
  end)

-- Bring an app forward: focus its window, restore one if all are minimized,
-- or launch/reopen it (which gives Finder and the rest a fresh window).
local function focusOrOpen(bundleID)
  return function()
    hyper.used = true
    local app = hs.application.get(bundleID)
    if app then
      local minimized
      for _, win in ipairs(app:allWindows()) do
        if win:isStandard() then
          if not win:isMinimized() then app:activate(); return end
          minimized = minimized or win
        end
      end
      if minimized then minimized:unminimize(); minimized:focus(); return end
    end
    hs.task.new("/usr/bin/open", nil, { "-b", bundleID }):start()
  end
end

hyper:bind({}, "b", focusOrOpen("org.mozilla.firefox"))
hyper:bind({}, "t", focusOrOpen("com.googlecode.iterm2"))
hyper:bind({}, "a", focusOrOpen("com.anthropic.claudefordesktop"))
hyper:bind({}, "e", focusOrOpen("com.apple.finder"))

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
