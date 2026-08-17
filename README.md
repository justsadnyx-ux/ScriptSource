# Rayfield Ultimate

Custom Rayfield UI Library for Roblox Executors. Feature-rich, themeable, auto-updating.

## Loadstring

```lua
loadstring(game:HttpGet("https://gitlab.com/justsadnyx/Rayfield-Ultimate/-/raw/main/loadstring.lua"))()
```

## Features

### Core UI
- **Window** - Draggable, minimizable, with drop shadow
- **Tabs** - Switchable tab system with icons
- **Elements** - Button, Toggle, Slider, Dropdown, Input, Paragraph, Separator, ColorPicker, Keybind
- **Sections** - Organize elements with labeled dividers

### Update System
- **Update Status Section** - Built-in `CreateUpdateSection()` shows Up to Date / Outdated with live indicator
- **Update Now Button** - One-click fetch from GitLab, caches source locally
- **Auto-Check** - Polls GitLab every 5 minutes for new versions
- **Manual Check** - "Check Again" button to force a version check
- **Changelog** - Tracks what's new in each version

### Script Hub
- Browse, search, and filter scripts
- Favorite scripts (persisted to config)
- One-click execute with error reporting

### Theme Engine
- 8 built-in themes: Default, Dark, Neon, Ocean, Mint, Crimson, Frost
- Switch themes at runtime

### Key System
- Protect scripts with key validation
- Configurable max attempts
- "Get Key" link button
- Copy-to-clipboard integration

### Console
- Timestamped log output (normal, info, warn, error)
- Clear and Copy buttons
- 500 line buffer

### Notifications
- Animated slide-in notifications
- Types: Success, Error, Warning, Info
- Auto-dismiss with configurable duration
- Manual close

### Built-in Tools
- **ESP** - Player names + distance tags (always-on-top BillboardGui)
- **Anti-AFK** - Prevents idle kicks via VirtualUser
- **FPS Boost** - Disables particles, trails, shadows, fog
- **Speed / Jump / Gravity Sliders** - Quick character mods

### Session Management
- Uptime tracker in footer
- Live player count in footer
- Clean shutdown with animated slide-down
- Connection cleanup (no orphaned events)
- State save/restore between sessions

## Quick Start

```lua
local Rayfield = loadstring(game:HttpGet("https://gitlab.com/justsadnyx/Rayfield-Ultimate/-/raw/main/loadstring.lua"))()

local Window = Rayfield:CreateWindow({
    Name = "My Script",
    Theme = "Default",
})

-- Updates tab with version status
local UpdatesTab = Window:CreateTab("Updates", "")
UpdatesTab:CreateUpdateSection()

-- Your content
local MainTab = Window:CreateTab("Main", "")
MainTab:CreateButton({
    Name = "Click Me",
    Callback = function()
        Rayfield:Notify({Title = "Hello!", Content = "Clicked!", Duration = 3, Type = "Success"})
    end,
})
```

## API Reference

### Window
```lua
Rayfield:CreateWindow(config)
Rayfield:CreateTab(config)
Rayfield:Shutdown()
Rayfield:GetVersion()
Rayfield:GetSession()
```

### Update System
```lua
Tab:CreateUpdateSection()              -- Add update status UI to a tab
Rayfield:CheckForUpdates()             -- Manual version check
Rayfield:UpdateNow()                   -- Download latest from GitLab
Rayfield:RefreshUpdateStatus()         -- Refresh the UI display
```

### Elements
```lua
Tab:CreateSection(name)
Tab:CreateButton(config)
Tab:CreateToggle(config)
Tab:CreateSlider(config)
Tab:CreateDropdown(config)
Tab:CreateInput(config)
Tab:CreateKeybind(config)
Tab:CreateParagraph(config)
Tab:CreateSeparator()
Tab:CreateColorPicker(config)
```

### Systems
```lua
Rayfield:Notify(config)
Rayfield:ToggleConsole()
Rayfield:LogToConsole(text, type)
Rayfield:ClearConsole()
Rayfield:OpenScriptHub()
Rayfield:AddToScriptHub(config)
Rayfield:ChangeTheme(name)
Rayfield:GetThemes()
```

## Themes

| Theme | Style |
|-------|-------|
| Default | Purple accent, clean modern |
| Dark | Red accent, deep black |
| Neon | Magenta/cyan, cyberpunk |
| Ocean | Blue accent, cool tones |
| Mint | Green accent, fresh |
| Crimson | Deep red, dark crimson |
| Frost | Ice blue, frosty |

## Config

Config is saved to `RayfieldU_Config/` folder. Toggles, dropdowns, and favorites persist between sessions.

## License

Free to use. Credit appreciated.
