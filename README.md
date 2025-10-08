# 🖱️ Smooth Mouse

A lightweight utility for smooth cursor transitions between multiple monitors with intelligent height mapping.

## ✨ What It Does

Smooth Mouse enhances multi-monitor setups by maintaining proportional cursor positioning when moving between displays. Instead of jarring jumps or unexpected cursor positions, the tool calculates percentage-based vertical positioning to ensure your cursor appears exactly where you expect it.

### Key Features

- **🎯 Percentage-Based Positioning** - Maintains relative cursor height across monitors
- **⚡ Real-Time Detection** - Monitors cursor position every 10ms for instant transitions
- **🔄 Bidirectional Support** - Works seamlessly in both directions (primary ↔ secondary)
- **💻 System Tray Integration** - Runs quietly in the background with enable/disable toggle
- **🎨 Custom Icon Support** - Uses your custom icon file for branding

## 🛠️ How It Works

When your cursor crosses from one monitor to another:

1. **Detects the transition** by monitoring for abrupt position changes (>100 pixels)
2. **Calculates the percentage** of vertical screen height where the cursor was positioned
3. **Applies that same percentage** to the target monitor's height
4. **Repositions the cursor** at the equivalent relative height

This means if you exit the primary monitor at 50% screen height, you'll enter the secondary monitor at 50% of *its* screen height - regardless of resolution differences.

## 📋 Requirements

- Windows OS with PowerShell
- `Smooth-mouse.ico` icon file (must be in the same directory)
- `ps2exe` PowerShell module (for compilation)

## 🔨 Building the EXE

### Install ps2exe (if not already installed)

```powershell
Install-Module ps2exe -Scope CurrentUser
```

### Compile the Script

Run this command from the directory containing the script:

```powershell
ps2exe -inputFile 'Smooth-Mouse.ps1' -outputFile 'Smooth-Mouse.exe' -iconFile 'Smooth-mouse.ico' -noConsole -noOutput
```

**Command Breakdown:**
- `-inputFile` - Source PowerShell script
- `-outputFile` - Destination executable name
- `-iconFile` - Custom icon to embed in the EXE
- `-noConsole` - Runs without showing a PowerShell console window
- `-noOutput` - Suppresses compiler output messages

## 📁 File Structure

```
Monitor location/
├── Smooth-Mouse.ps1              # Source script
├── Smooth-mouse.ico              # Required icon file
├── Smooth-Mouse.exe              # Compiled executable
└── README.md                     # This file
```

## 🚀 Usage

1. Ensure `Smooth-mouse.ico` is in the same directory as the EXE
2. Run `Smooth-Mouse.exe`
3. Look for the tray icon in your system tray
4. Right-click the tray icon to:
   - **Disable** - Temporarily pause cursor transitions
   - **Enable** - Resume cursor transitions
   - **Exit** - Close the application

## ⚙️ Technical Details

### Script Architecture

- **Monitor Detection** - Uses `System.Windows.Forms.Screen` to identify primary/secondary displays
- **Position Tracking** - Polls cursor position every 10ms via Windows Forms Timer
- **Transition Logic** - Implements percentage-based height calculations with abrupt change detection
- **System Tray** - Uses `NotifyIcon` with `ContextMenuStrip` for modern Windows compatibility

### Customization

Edit the threshold value in `Test-AbruptChange` function to adjust sensitivity:

```powershell
$threshold = 100  # Pixels - increase for less sensitive detection
```

## 📝 Version History

**v1.0.1**
- Percentage-based positioning in both directions
- Removed position storage for cleaner bidirectional transitions
- Updated to ContextMenuStrip for better tray menu compatibility
- Simplified icon loading (file-based only)

## 🎯 Perfect For

- Multi-monitor developers and designers
- Users with different resolution displays
- Anyone frustrated by cursor position inconsistencies
- Streamers and content creators with multiple screens

---

**Made with ❤️ for seamless multi-monitor workflows**
