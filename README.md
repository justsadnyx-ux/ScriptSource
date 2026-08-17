# Rayfield Ultimate

Custom Rayfield UI Library for Roblox Executors with built-in features.

## Features

- **Script Hub** - Built-in script browser with favorites, search, and one-click execute
- **Theme Engine** - 5 built-in themes (Default, Dark, Neon, Ocean, Mint) + custom theme support
- **Key System** - Protect your scripts with a key-based access system
- **Console** - Built-in output console for debugging and logging
- **Notifications** - Animated notification system with types (Success, Error, Warning, Info)
- **Enhanced Window** - Draggable, minimizable, resizable window with shadows
- **Remote Updates** - Auto-checks GitLab for new versions
- **Session Management** - Clean shutdown, uptime tracking, connection cleanup

## Loadstring

```lua
loadstring(game:HttpGet("https://gitlab.com/justsadnyx/Rayfield-Ultimate/-/raw/main/loadstring.lua"))()
```

## Quick Start

```lua
local Rayfield = loadstring(game:HttpGet("https://gitlab.com/justsadnyx/Rayfield-Ultimate/-/raw/main/loadstring.lua"))()

local Window = Rayfield:CreateWindow({
    Name = "My Script",
    Theme = "Default",
    KeySystem = false,
})

local Tab = Window:CreateTab("Main", "")
Tab:CreateButton({
    Name = "Click Me",
    Callback = function()
        Rayfield:Notify({Title = "Hello!", Content = "Button clicked!", Duration = 3, Type = "Success"})
    end,
})
```

## Themes

| Theme | Style |
|-------|-------|
| Default | Purple accent, clean modern look |
| Dark | Red accent, deep dark background |
| Neon | Magenta/cyan, cyberpunk vibes |
| Ocean | Blue accent, cool ocean tones |
| Mint | Green accent, fresh and clean |

## API

### Window
```lua
Rayfield:CreateWindow(config) -- Creates the main window
Rayfield:CreateTab(config)    -- Creates a new tab
Rayfield:Shutdown()           -- Shuts down everything
```

### Elements
```lua
Tab:CreateButton(config)
Tab:CreateToggle(config)
Tab:CreateSlider(config)
Tab:CreateDropdown(config)
Tab:CreateInput(config)
Tab:CreateParagraph(config)
Tab:CreateSeparator()
Tab:CreateSection(name)
Tab:CreateColorPicker(config)
```

### Systems
```lua
Rayfield:Notify(config)            -- Show notification
Rayfield:ToggleConsole()           -- Toggle console
Rayfield:LogToConsole(text, type)  -- Log to console
Rayfield:ClearConsole()            -- Clear console
Rayfield:OpenScriptHub()           -- Toggle script hub
Rayfield:AddToScriptHub(config)    -- Add script to hub
Rayfield:ChangeTheme(name)         -- Switch theme
Rayfield:GetThemes()               -- Get available themes
Rayfield:GetVersion()              -- Get current version
Rayfield:GetSession()              -- Get session info
```

## Config

Config is saved to `RayfieldU_Config/` folder automatically. Toggle states, dropdown selections, and script hub favorites persist between sessions.

## License

Free to use. Credit appreciated.
