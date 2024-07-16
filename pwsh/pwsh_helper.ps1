Write-Host "✅ Helper script invoked successfully" -ForegroundColor Green

Function Test-CommandExists {
    Param ($command)
    $oldPreference = $ErrorActionPreference
    $ErrorActionPreference = 'SilentlyContinue'
    try { if (Get-Command $command) { RETURN $true } }
    Catch { Write-Host "$command does not exist"; RETURN $false }
    Finally { $ErrorActionPreference = $oldPreference }
} 

function Install-NerdFont {
    $zipPath = "$env:TEMP\$font_folder.zip"
    $extractPath = "$env:TEMP\$font_folder"
    $shell = New-Object -ComObject Shell.Application
    $fonts = $shell.Namespace(0x14)
    try {
        # Download the Nerd Font zip file
        Write-Host "Downloading $font Nerd Font..." -ForegroundColor Green
        Invoke-WebRequest -Uri $font_url -OutFile $zipPath
        # Create the directory to extract the files
        if (-Not (Test-Path -Path $extractPath)) {
            New-Item -ItemType Directory -Path $extractPath | Out-Null
        }
        # Extract the zip file
        Write-Host "Extracting $font Nerd Font..." -ForegroundColor Green
        Expand-Archive -Path $zipPath -DestinationPath $extractPath -Force
        # Find the specific font file
        $fontFile = Get-ChildItem -Path $extractPath -Filter $fontFileName | Select-Object -First 1
        if (-not $fontFile) {
            throw "❌ Font file '$fontFileName' not found in the extracted files."
        }
        # Copy the font file to the Windows Fonts directory
        Write-Host "Installing $font Nerd Font..." -ForegroundColor Green
        $fonts.CopyHere($fontFile.FullName, 0x10)
        Write-Host "$font Nerd Font installed successfully!" -ForegroundColor Green
        Write-Host "📝 Make sure to set the font as default in your terminal settings." -ForegroundColor Blue
    } catch {
        Write-Host "❌ An error occurred: $_" -ForegroundColor Red
    } finally {
        # Clean up
        Write-Host "Cleaning up temporary files..." -ForegroundColor Green
        Remove-Item -Path $zipPath -Force
        Remove-Item -Path $extractPath -Recurse -Force
    }
}

function Test-ohmyposh {  
    if (Test-CommandExists oh-my-posh) {
        Set-ConfigValue -Key "ohmyposh_installed" -Value "True"
    } else {
        Write-Host "❌ OhMyPosh is not installed." -ForegroundColor Red
        $installOhMyPosh = Read-Host "Do you want to install Oh-My-Posh? (Y/N)"
        if ($installOhMyPosh -eq 'Y' -or $installOhMyPosh -eq 'y') {
            winget install JanDeDobbeleer.OhMyPosh --accept-package-agreements --accept-source-agreements
        } else {
            Write-Host "❌ Oh-My-Posh installation skipped." -ForegroundColor Yellow
        }
    } 
}

function Test-$font {
    $nerdfonts = Get-Font *$font*
    if ($nerdfonts) {
        Set-ConfigValue -Key "${font}_installed" -Value "True"
    } else {
        Write-Host "❌ No Nerd-Fonts are installed." -ForegroundColor Red
        $installNerdFonts = Read-Host "Do you want to install $font NerdFont? (Y/N)"
        if ($installNerdFonts -eq 'Y' -or $installNerdFonts -eq 'y') {
            Install-NerdFont
        } else {
            Write-Host "❌ NerdFonts installation skipped." -ForegroundColor Yellow
            Set-ConfigValue -Key "$font_installed" -Value "False"
        }
    }
}

function Update-PowerShell {
    if (-not $global:canConnectToGitHub) {
        Write-Host "❌ Skipping PowerShell update or installation check due to GitHub.com not responding within 1 second." -ForegroundColor Yellow
        return
    }
    try {
        $isInstalled = $null -ne (Get-Command pwsh -ErrorAction SilentlyContinue)
        $updateNeeded = $false
        if ($isInstalled) {
            $currentVersion = $PSVersionTable.PSVersion.ToString()
        } else {
            $currentVersion = "0.0"
        }
        $gitHubApiUrl = "https://api.github.com/repos/PowerShell/PowerShell/releases/latest"
        $latestReleaseInfo = Invoke-RestMethod -Uri $gitHubApiUrl
        $latestVersion = $latestReleaseInfo.tag_name.Trim('v')
        if ($currentVersion -lt $latestVersion) {
            $updateNeeded = $true
        }
        if ($updateNeeded -and $isInstalled) {
            Write-Host "Updating PowerShell..." -ForegroundColor Yellow
            winget upgrade "Microsoft.PowerShell" --accept-source-agreements --accept-package-agreements
        } elseif ($updateNeeded -and -not $isInstalled) {
            Write-Host "Installing PowerShell..." -ForegroundColor Yellow
            winget install "Microsoft.PowerShell" --accept-source-agreements --accept-package-agreements
        } else {
            Write-Host "✅ PowerShell is up to date." -ForegroundColor Green
        }
    } catch {
        Write-Error "❌ Failed to update or install PowerShell. Error: $_"
    }
}

# Function to show a GUI Message Box
# Source: https://stackoverflow.com/questions/58718191/is-there-a-way-to-display-a-pop-up-message-box-in-powershell-that-is-compatible
function Show-MessageBox {
    [CmdletBinding(PositionalBinding=$false)]
    param(
        [Parameter(Mandatory, Position=0)]
        [string] $Message,
        [Parameter(Position=1)]
        [string] $Title,
        [Parameter(Position=2)]
        [ValidateSet('OK', 'OKCancel', 'AbortRetryIgnore', 'YesNoCancel', 'YesNo', 'RetryCancel')]
        [string] $Buttons = 'OK',
        [ValidateSet('Information', 'Warning', 'Stop')]
        [string] $Icon = 'Information',
        [ValidateSet(0, 1, 2)]
        [int] $DefaultButtonIndex
    )

    $buttonMap = @{ 
        'OK'               = @{ buttonList = 'OK'; defaultButtonIndex = 0 }
        'OKCancel'         = @{ buttonList = 'OK', 'Cancel'; defaultButtonIndex = 0; cancelButtonIndex = 1 }
        'AbortRetryIgnore' = @{ buttonList = 'Abort', 'Retry', 'Ignore'; defaultButtonIndex = 2; cancelButtonIndex = 0 }
        'YesNoCancel'      = @{ buttonList = 'Yes', 'No', 'Cancel'; defaultButtonIndex = 2; cancelButtonIndex = 2 }
        'YesNo'            = @{ buttonList = 'Yes', 'No'; defaultButtonIndex = 0; cancelButtonIndex = 1 }
        'RetryCancel'      = @{ buttonList = 'Retry', 'Cancel'; defaultButtonIndex = 0; cancelButtonIndex = 1 }
    }

    $numButtons = $buttonMap[$Buttons].buttonList.Count
    $defaultIndex = [math]::Min($numButtons - 1, ($buttonMap[$Buttons].defaultButtonIndex, $DefaultButtonIndex)[$PSBoundParameters.ContainsKey('DefaultButtonIndex')])
    $cancelIndex = $buttonMap[$Buttons].cancelButtonIndex
    Add-Type -AssemblyName System.Windows.Forms

    # Create a hidden form and set it as TopMost
    $form = New-Object System.Windows.Forms.Form
    $form.TopMost = $true
    $form.ShowInTaskbar = $false
    $form.WindowState = 'Minimized'
    $form.Show()
    $form.Hide()

    # Show the message box with the hidden form as the owner
    $result = [System.Windows.Forms.MessageBox]::Show($form, $Message, $Title, $Buttons, $Icon, $defaultIndex * 256).ToString()

    # Close the hidden form
    $form.Close()
    $form.Dispose()

    # Output the result
    return $result
}
