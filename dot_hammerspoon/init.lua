-- Key remaps and the Caps Lock hyper key. Needs Accessibility access
-- (System Settings > Privacy & Security).

hs.autoLaunch(true)

-- Reload whenever chezmoi rewrites this file
configWatcher = hs.pathwatcher.new(hs.configdir, hs.reload):start()

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
-- below. Tapping it alone does nothing.
hyper = hs.hotkey.modal.new()
hs.hotkey.bind({}, "f18", function() hyper:enter() end, function() hyper:exit() end)

-- Bring an app forward: focus its window, restore one if all are minimized,
-- or launch/reopen it (which gives Finder and the rest a fresh window).
local function focusOrOpen(bundleID)
  return function()
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

hs.alert.show("Hotkeys loaded")
