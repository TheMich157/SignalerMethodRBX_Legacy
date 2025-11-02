# Train Signal System for Roblox

Complete train signal controller with chat commands. Single file system.

## Light Positions

- **Light1**: Top light (Green when set)
- **Light2**: Second light (Yellow)
- **Light3**: Third light (Red - main stop signal)
- **Light4**: Fourth light (Yellow)

## Commands

Use these chat commands in-game to control the signal:

- `!stop` - Red light at Light3 (Stop signal)
- `!vmax` - Green light at Light1 (Maximum speed)
- `!yellow` - Yellow light at Light2 only
- `!doubleyellow` - Yellow lights at Light2 and Light4
- `!greenyellow` - Green at Light1, Yellow at Light4

## Important Rules

- When the signal is NOT in stop state, Light3 (the main red stop signal) must be set to **Black** (off)
- Green light always appears at Light1 (top)
- Yellow lights appear at Light2 and/or Light4 based on the state
- Lights are controlled as **parts** (color and material), not PointLights

## Setup Instructions

### Step 1: Prepare Your Roblox Model

1. Create a **folder** in workspace named `Semaphores`
2. Create your train signal models/folders inside `Semaphores`
3. Each semaphore should contain 4 light parts named: `Light1`, `Light2`, `Light3`, `Light4`
4. Example structure: `workspace.Semaphores.Semaphore1` (with Light1-Light4 inside)

### Step 2: Add Script to Roblox Studio

1. Open Roblox Studio
2. Go to **ServerScriptService**
3. Add `TrainSignalSystem.lua` as a **Server Script**

### Step 3: Model Structure

No configuration needed! The system automatically finds all semaphores in `workspace.Semaphores` folder.

**Required structure:**
```
workspace
  └── Semaphores (Folder)
      ├── Semaphore1 (Model/Folder)
      │   ├── Light1 (BasePart)
      │   ├── Light2 (BasePart)
      │   ├── Light3 (BasePart)
      │   └── Light4 (BasePart)
      └── Semaphore2 (Model/Folder) [optional - for future expansion]
          ├── Light1 (BasePart)
          ├── Light2 (BasePart)
          ├── Light3 (BasePart)
          └── Light4 (BasePart)
```

### Step 4: Test

1. Run your game
2. Type in chat: `!vmax`, `!stop`, `!yellow`, etc.
3. The signal should change accordingly!

## Multiple Semaphores (Future Expansion)

The system supports multiple semaphores. Each semaphore can be controlled independently.

### Adding Multiple Semaphores

Simply add more models/folders to `workspace.Semaphores` folder! The system automatically discovers all semaphores.

**To add Semaphore2:**
1. Create `workspace.Semaphores.Semaphore2`
2. Add `Light1`, `Light2`, `Light3`, `Light4` inside it
3. The system will automatically detect and register it on next server start

No code changes needed!

### Programmatic Control

You can also control signals programmatically:

```lua
local TrainSignal = require(ServerScriptService.TrainSignalSystem)

-- Get a semaphore
local signal = TrainSignal.GetSemaphore("default")
if signal then
	signal:SetVmax()
	signal:SetStop()
	-- etc.
end

-- Or add a new one
TrainSignal.AddSemaphore("mySignal", light1, light2, light3, light4)
```

## Dispatch Panel UI (Optional)

A modern GUI panel for controlling train signals with buttons instead of chat commands.

### Setup for Dispatch Panel

1. **Add Remote Handler** (Server):
   - Place `TrainSignalRemoteHandler.lua` as a **Server Script** in **ServerScriptService**
   - This handles commands from the UI panel

2. **Add Chat Handler** (Client):
   - Place `TrainSignalChatHandler.lua` as a **LocalScript** in:
     - `StarterGui`, OR
     - `StarterPlayer` > `StarterPlayerScripts`
   - This handles displaying `!help` and `!list` messages in chat

3. **Add UI Panel** (Client - Optional):
   - Place `TrainSignalDispatchPanel.lua` as a **LocalScript** in:
     - `StarterGui`, OR
     - `StarterPlayer` > `StarterPlayerScripts`
   - This creates the GUI panel for players

### Features

- **Modern UI Design**: Clean, rounded interface with hover effects
- **Button Controls**: Click buttons instead of typing commands
- **Status Display**: See current signal state at a glance
- **Toggle Panel**: Show/hide the panel with the train icon button
- **Real-time Updates**: Status updates immediately when buttons are clicked

### UI Controls

- **STOP** - Red button (sets signal to stop)
- **VMAX** - Green button (sets signal to maximum speed)
- **YELLOW** - Yellow button (single yellow)
- **DOUBLE YELLOW** - Yellow button (double yellow)
- **GREEN+YELLOW** - Green/Yellow button (green + yellow)

The panel can be toggled with the 🚂 button that appears when the panel is closed.

## Files

- **TrainSignalSystem.lua** - Complete system (Server Script)
- **TrainSignalRemoteHandler.lua** - Remote handler for UI (Server Script)
- **TrainSignalChatHandler.lua** - Chat message display (LocalScript for clients)
- **TrainSignalDispatchPanel.lua** - UI Panel (LocalScript for clients - optional)
