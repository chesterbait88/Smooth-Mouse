# Easy-mouse-transition 1.0.1
# A utility to help with cursor movement between multiple monitors

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Global variables to store positions
$script:previousPosition = $null
$script:isOnPrimaryMonitor = $true
$script:primary = [System.Windows.Forms.Screen]::PrimaryScreen
$script:isEnabled = $true  # Flag to enable/disable the script functionality

# Function to get current mouse position
function Get-MousePosition {
    [System.Windows.Forms.Cursor]::Position
}

# Function to set mouse position
function Set-MousePosition([System.Drawing.Point]$point) {
    [System.Windows.Forms.Cursor]::Position = $point
    # Return nothing to suppress output
    return
}

# Function to check if point is on primary monitor
function Test-PointOnPrimaryMonitor([System.Drawing.Point]$point) {
    return $script:primary.Bounds.Contains($point)
}

# Function to check if position change is abrupt (indicates monitor switch)
function Test-AbruptChange([System.Drawing.Point]$current, [System.Drawing.Point]$previous) {
    if ($null -eq $previous) { return $false }
    $threshold = 100  # Adjust this value to determine what constitutes an "abrupt" change
    $deltaX = [Math]::Abs($current.X - $previous.X)
    $deltaY = [Math]::Abs($current.Y - $previous.Y)
    return ($deltaX -gt $threshold) -or ($deltaY -gt $threshold)
}

# Function to calculate percentage-based position when transitioning between monitors
function Get-PercentageBasedPosition([System.Drawing.Point]$point, [bool]$movingToSecondary) {
    if ($movingToSecondary) {
        # Transitioning from primary to secondary
        $primaryHeight = $script:primary.Bounds.Height
        $relativeY = $point.Y / $primaryHeight  # Get percentage position (0-1)

        # Get secondary monitor
        $secondary = [System.Windows.Forms.Screen]::AllScreens | Where-Object { -not $_.Primary }
        if ($secondary) {
            # Calculate new Y position maintaining same relative height
            $newY = [Math]::Round($relativeY * $secondary.Bounds.Height)
            # Position at left edge of secondary monitor
            $newX = $secondary.Bounds.X
            return New-Object System.Drawing.Point($newX, $newY)
        }
    } else {
        # Transitioning from secondary to primary
        $secondary = [System.Windows.Forms.Screen]::AllScreens | Where-Object { -not $_.Primary }
        if ($secondary) {
            $secondaryHeight = $secondary.Bounds.Height
            # Calculate Y relative to secondary monitor's bounds
            $relativeY = ($point.Y - $secondary.Bounds.Y) / $secondaryHeight  # Get percentage position (0-1)

            # Apply to primary monitor
            $primaryHeight = $script:primary.Bounds.Height
            $newY = [Math]::Round($relativeY * $primaryHeight)
            # Position at right edge of primary monitor
            $newX = $script:primary.Bounds.Right - 1
            return New-Object System.Drawing.Point($newX, $newY)
        }
    }
    return $point
}

# Create global variables for tray icon components
$script:notifyIcon = New-Object System.Windows.Forms.NotifyIcon
$script:contextMenu = New-Object System.Windows.Forms.ContextMenuStrip
$script:menuEnable = New-Object System.Windows.Forms.ToolStripMenuItem
$script:menuExit = New-Object System.Windows.Forms.ToolStripMenuItem

# Function to toggle enabled/disabled state
function Toggle-EnabledState {
    if ($script:isEnabled) {
        $script:isEnabled = $false
        $script:menuEnable.Text = "Enable"
        $script:notifyIcon.Text = "Smooth Mouse (Disabled)"
    } else {
        $script:isEnabled = $true
        $script:menuEnable.Text = "Disable"
        $script:notifyIcon.Text = "Smooth Mouse (Enabled)"
    }
}

# Function to exit the application
function Exit-Application {
    $script:notifyIcon.Visible = $false
    $script:notifyIcon.Dispose()
    $script:contextMenu.Dispose()
    [System.Windows.Forms.Application]::Exit()
}

# Function to create tray icon
function Initialize-TrayIcon {
    # Set up the notify icon
    $script:notifyIcon.Text = "Smooth Mouse (Enabled)"

    # Define possible locations for the icon file
    $possibleLocations = @()

    # Add current directory
    $possibleLocations += (Get-Location).Path

    # Add script directory if available
    if ($PSScriptRoot) {
        $possibleLocations += $PSScriptRoot
    }

    # Add execution path if available
    if ($MyInvocation.MyCommand.Path) {
        $possibleLocations += (Split-Path -Parent $MyInvocation.MyCommand.Path)
    }

    # Try to find and load the icon file
    $iconFound = $false
    foreach ($location in $possibleLocations) {
        $iconFile = Join-Path -Path $location -ChildPath "Easy-mouse.ico"
        if (Test-Path -Path $iconFile) {
            try {
                $script:notifyIcon.Icon = New-Object System.Drawing.Icon($iconFile)
                $iconFound = $true
                break
            }
            catch {
                Write-Host ("Error loading icon from {0}: {1}" -f $iconFile, $_.Exception.Message)
            }
        }
    }

    # If running as EXE, try to extract icon from the executable itself
    if (-not $iconFound -and $MyInvocation.MyCommand.Path -match '\.exe$') {
        try {
            $exePath = $MyInvocation.MyCommand.Path
            $extractIcon = Add-Type -MemberDefinition @'
            [DllImport("shell32.dll", CharSet = CharSet.Auto)]
            public static extern IntPtr ExtractIcon(IntPtr hInst, string lpszExeFileName, int nIconIndex);
'@ -Name ExtractIcon -Namespace Shell32 -PassThru

            $hIcon = $extractIcon::ExtractIcon([IntPtr]::Zero, $exePath, 0)
            if ($hIcon -ne [IntPtr]::Zero) {
                $script:notifyIcon.Icon = [System.Drawing.Icon]::FromHandle($hIcon)
                $iconFound = $true
            }
        }
        catch {
            Write-Host ("Error extracting icon from executable: {0}" -f $_.Exception.Message)
        }
    }

    # If all else fails, use default system icon
    if ($null -eq $script:notifyIcon.Icon) {
        $script:notifyIcon.Icon = [System.Drawing.SystemIcons]::Application
        Write-Host "Using default system icon"
    }

    # Set up menu items
    $script:menuEnable.Text = "Disable"
    $script:menuEnable.Add_Click({ Toggle-EnabledState })

    $script:menuExit.Text = "Exit"
    $script:menuExit.Add_Click({ Exit-Application })

    # Add menu items to context menu
    $script:contextMenu.Items.Add($script:menuEnable) | Out-Null
    $script:contextMenu.Items.Add($script:menuExit) | Out-Null

    # Finish setting up the notify icon
    $script:notifyIcon.ContextMenuStrip = $script:contextMenu
    $script:notifyIcon.Visible = $true
}

# Create and show the tray icon
[void](Initialize-TrayIcon)

# Create a form to process Windows messages
$form = New-Object System.Windows.Forms.Form
$form.WindowState = [System.Windows.Forms.FormWindowState]::Minimized
$form.ShowInTaskbar = $false
$form.Width = 0
$form.Height = 0

# Set up a timer to handle the mouse monitoring
$timer = New-Object System.Windows.Forms.Timer
$timer.Interval = 10
$timer.Add_Tick({
    if (-not $script:isEnabled) {
        # Skip processing when disabled
        return
    }

    $currentPosition = Get-MousePosition
    $onPrimary = Test-PointOnPrimaryMonitor $currentPosition

    # Check for abrupt position change while leaving primary
    if ($script:isOnPrimaryMonitor -and -not $onPrimary) {
        if (Test-AbruptChange $currentPosition $script:previousPosition) {
            $script:isOnPrimaryMonitor = $false
            # Set percentage-based position on secondary monitor
            $relativePos = Get-PercentageBasedPosition $script:previousPosition $true
            [void](Set-MousePosition $relativePos)
        }
    }
    # Mouse returning to primary monitor
    elseif (-not $script:isOnPrimaryMonitor -and $onPrimary) {
        if (Test-AbruptChange $currentPosition $script:previousPosition) {
            # Set percentage-based position on primary monitor
            $relativePos = Get-PercentageBasedPosition $script:previousPosition $false
            [void](Set-MousePosition $relativePos)
        }
        $script:isOnPrimaryMonitor = $true
    }

    $script:previousPosition = $currentPosition
})

# Start the timer
[void]($timer.Start())

# Main application loop
try {
    # Start the Windows Forms message loop
    [System.Windows.Forms.Application]::Run($form)
}
finally {
    # Clean up resources
    if ($null -ne $script:notifyIcon) {
        $script:notifyIcon.Visible = $false
        $script:notifyIcon.Dispose()
    }
    if ($null -ne $script:contextMenu) {
        $script:contextMenu.Dispose()
    }
    if ($null -ne $timer) {
        $timer.Stop()
        $timer.Dispose()
    }
    if ($null -ne $form) {
        $form.Dispose()
    }
}