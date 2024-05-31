Write-Host "✅ Helper script invoked successfully" -ForegroundColor Green

Function Test-CommandExists {
    Param ($command)
    $oldPreference = $ErrorActionPreference
    $ErrorActionPreference = 'SilentlyContinue'
    try { if (Get-Command $command) { RETURN $true } }
    Catch { Write-Host "$command does not exist"; RETURN $false }
    Finally { $ErrorActionPreference = $oldPreference }
} 

function Install-FiraCode {
    $url = "https://github.com/ryanoasis/nerd-fonts/releases/download/v3.2.1/FiraCode.zip"
    $zipPath = "$env:TEMP\FiraCode.zip"
    $extractPath = "$env:TEMP\FiraCode"
    $fontFileName = "FiraCodeNerdFontMono-Regular.ttf"
    $shell = New-Object -ComObject Shell.Application
    $fonts = $shell.Namespace(0x14)
    try {
        # Download the FiraCode Nerd Font zip file
        Write-Host "Downloading FiraCode Nerd Font..." -ForegroundColor Green
        Invoke-WebRequest -Uri $url -OutFile $zipPath
        # Create the directory to extract the files
        if (-Not (Test-Path -Path $extractPath)) {
            New-Item -ItemType Directory -Path $extractPath | Out-Null
        }
        # Extract the zip file
        Write-Host "Extracting FiraCode Nerd Font..." -ForegroundColor Green
        Expand-Archive -Path $zipPath -DestinationPath $extractPath -Force
        # Find the specific font file
        $fontFile = Get-ChildItem -Path $extractPath -Filter $fontFileName | Select-Object -First 1
        if (-not $fontFile) {
            throw "❌ Font file '$fontFileName' not found in the extracted files."
        }
        # Copy the font file to the Windows Fonts directory
        Write-Host "Installing FiraCode Nerd Font..." -ForegroundColor Green
        $fonts.CopyHere($fontFile.FullName, 0x10)
        Write-Host "FiraCode Nerd Font installed successfully!" -ForegroundColor Green
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

function Test-vscode {
    if (Test-CommandExists code) {
        Set-ConfigValue -Key "vscode_installed" -Value "True"
    } else {
        $installVSCode = Read-Host "Do you want to install Visual Studio Code? (Y/N)"
        if ($installVSCode -eq 'Y' -or $installVSCode -eq 'y') {
            winget install Microsoft.VisualStudioCode --accept-package-agreements --accept-source-agreements
        } else {
            Write-Host "❌ Visual Studio Code installation skipped." -ForegroundColor Yellow
        }
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

function Test-FiraCode {
    $firaCodeFonts = Get-Font *FiraCode*
    if ($firaCodeFonts) {
        Set-ConfigValue -Key "FiraCode_installed" -Value "True"
    } else {
        Write-Host "❌ No Nerd-Fonts are installed." -ForegroundColor Red
        $installNerdFonts = Read-Host "Do you want to install FiraCode NerdFont? (Y/N)"
        if ($installNerdFonts -eq 'Y' -or $installNerdFonts -eq 'y') {
            Install-FiraCode
        } else {
            Write-Host "❌ NerdFonts installation skipped." -ForegroundColor Yellow
            Set-ConfigValue -Key "FiraCode_installed" -Value "False"
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
