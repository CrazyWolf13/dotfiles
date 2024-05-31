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
        Write-Host "📝 Make sure to set the font as default in your terminal settings." -ForegroundColor Red
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
        $installOhMyPosh = Read-Host "Do you want to install Oh-My-Posh? (Y/N)"
        if ($installOhMyPosh -eq 'Y' -or $installOhMyPosh -eq 'y') {
            winget install JanDeDobbeleer.OhMyPosh --accept-package-agreements --accept-source-agreements
            wt.exe
            exit
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
        Write-Host "❌ Skipping PowerShell update check due to GitHub.com not responding within 1 second." -ForegroundColor Yellow
        return
    }
    try {
        $updateNeeded = $false
        $currentVersion = $PSVersionTable.PSVersion.ToString()
        $gitHubApiUrl = "https://api.github.com/repos/PowerShell/PowerShell/releases/latest"
        $latestReleaseInfo = Invoke-RestMethod -Uri $gitHubApiUrl
        $latestVersion = $latestReleaseInfo.tag_name.Trim('v')
        if ($currentVersion -lt $latestVersion) {
            $updateNeeded = $true
        }
        if ($updateNeeded) {
            Write-Host "Updating PowerShell..." -ForegroundColor Yellow
            winget upgrade "Microsoft.PowerShell" --accept-source-agreements --accept-package-agreements
            Write-Host "PowerShell has been updated. Please restart your shell to reflect changes" -ForegroundColor Magenta
        } else {
            Write-Host "✅ PowerShell is up to date." -ForegroundColor Green
        }
    } catch {
        Write-Error "❌ Failed to update PowerShell. Error: $_"
    }
}
