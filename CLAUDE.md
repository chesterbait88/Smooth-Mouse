# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Smooth Mouse is a single-file PowerShell utility that provides smooth cursor transitions between multiple monitors with percentage-based height mapping. The entire application is self-contained in `Smooth-Mouse.ps1` and compiles to `Smooth-Mouse.exe`.

## Build Commands

### Compile PowerShell Script to EXE

Requires the `ps2exe` module. Install if needed:
```powershell
Install-Module ps2exe -Scope CurrentUser
```

Compile the script:
```powershell
ps2exe -inputFile 'Smooth-Mouse.ps1' -outputFile 'Smooth-Mouse.exe' -iconFile 'Smooth-mouse.ico' -noConsole -noOutput
```

**Note:** The `Smooth-mouse.ico` file must be present in the same directory.

## Architecture

### Core Components

The script uses a Windows Forms message loop with a 10ms timer to monitor cursor position:

- **Monitor Detection** (`Test-PointOnPrimaryMonitor`): Uses `System.Windows.Forms.Screen` to identify which monitor the cursor is on
- **Transition Detection** (`Test-AbruptChange`): Detects monitor transitions by identifying position jumps >100 pixels
- **Position Mapping** (`Get-PercentageBasedPosition`): Calculates percentage-based vertical positioning across monitors
- **Robust Position Setting** (`Set-MousePositionRobust`): Verifies cursor position after setting and retries up to 5 times with 5ms delays between attempts
- **Position Verification** (`Test-PositionMatch`): Checks if cursor is within 10 pixels of target position
- **System Tray** (`Initialize-TrayIcon`): Provides enable/disable toggle and exit controls via `ContextMenuStrip`

### Key Logic Flow

1. Timer polls cursor position every 10ms
2. First checks if there's a pending target position from a previous failed correction attempt
   - If yes, retries positioning up to 20 timer cycles before giving up
3. When cursor crosses monitor boundary (detected via abrupt position change >100px):
   - Calculate vertical position as percentage of source monitor height
   - Apply that percentage to target monitor height
   - Reposition cursor using robust positioning function
4. Robust positioning attempts to set position up to 5 times:
   - Sets cursor position
   - Waits 5ms for Windows to process
   - Verifies actual position matches target (within 10px tolerance)
   - If verification fails, retries immediately
   - If all immediate retries fail, stores target position for retry on next timer tick
5. Works bidirectionally (primary ↔ secondary)

### State Variables

- `$script:previousPosition`: Tracks last cursor position for delta calculations
- `$script:isOnPrimaryMonitor`: Boolean tracking current monitor
- `$script:isEnabled`: Controls whether transitions are active (toggled via tray menu)
- `$script:targetPosition`: Stores the intended cursor position when verification fails, enabling retry on subsequent timer ticks
- `$script:retryCount`: Counts retry attempts for the current positioning operation (max 20)

## Customization

### Transition Sensitivity

Adjust transition detection threshold in `Test-AbruptChange`:
```powershell
$threshold = 100  # Pixels - increase for less sensitive detection
```

### Position Verification Tolerance

Adjust position matching tolerance in `Test-PositionMatch`:
```powershell
[int]$tolerance = 100  # Pixels - cursor must be within this distance to target
```

### Retry Parameters

Adjust retry behavior in the timer logic and `Set-MousePositionRobust`:
```powershell
# In timer Add_Tick:
$script:retryCount -lt 2  # Maximum timer cycles for retries

# In Set-MousePositionRobust:
[int]$maxAttempts = 2  # Immediate retry attempts per positioning operation
Start-Sleep -Milliseconds 5  # Delay between retry attempts
```
