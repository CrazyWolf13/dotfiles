function Test-ExecPolicy {
    $execPolicy = Get-ExecutionPolicy
    if ($execPolicy -ne "RemoteSigned") {
        Write-Host "Execution Policy is not set to RemoteSigned. This can lead to errors, when trying to install this shell." -ForegroundColor Yellow
        Read-Host "Would you like to set the Execution Policy to RemoteSigned? (Y/N)"
        if ($? -eq 'Y') {
            Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned -Force
        }
    }
}


function Install-NuGet {
    # Install NuGet to ensure the other packages can be installed.
    $nugetProvider = Get-PackageProvider -Name NuGet -ErrorAction SilentlyContinue
    if (-not $nugetProvider) {
        Write-Host "NuGet provider not found. Installing..."
        Install-PackageProvider -Name NuGet -Force -Scope CurrentUser
        Import-PackageProvider -Name NuGet -Force
        Write-Host "NuGet provider installed."
    } else {
        Write-Host "NuGet provider is already installed."
    }
    # Trust the PSGallery repository for while installing this powershell profile.
    Set-PSRepository -Name "PSGallery" -InstallationPolicy Trusted
}


function Test-Pwsh {
    if (-not (Get-Command pwsh -ErrorAction SilentlyContinue)) {
        Write-Host "PowerShell Core (pwsh) is not installed. Starting the update..." -ForegroundColor Yellow
        Run-UpdatePowershell
        Start-Sleep -Seconds 8 # Wait for the update to finish
        Write-Host "Restarting the installation script with Powershell Core" -ForegroundColor Green
        Start-Process pwsh -ArgumentList "-NoExit", "-Command Invoke-Expression (Invoke-WebRequest -Uri '$githubBaseURL/Microsoft.PowerShell_profile.ps1'-UseBasicParsing).Content ; Install-Config"
        exit
    } else {
        Write-Host "✅ PowerShell Core (pwsh) is installed." -ForegroundColor Green
    }
}


function Test-CreateProfile {
    $profilePath = $PROFILE
    $profileDir = Split-Path -Path $profilePath -Parent
    $githubProfileUrl = "$githubBaseURL/Microsoft.PowerShell_profile.ps1"
    $blockVersion = "1.0.0" # Change this to the current version of the block

    # Create $PATH folder if not exists
    if (-not (Test-Path -Path $profileDir)) {
        New-Item -ItemType Directory -Path $profileDir -Force | Out-Null
    }
    
    # Create profile if not exists
    if (-not (Test-Path -Path $profilePath)) {
        New-Item -ItemType File -Path $profilePath | Out-Null
    }

    # Define the profile block with versioning
    $profileBlock = @"
# BEGIN unix-pwsh v$blockVersion
if (Test-Path (Join-Path -Path `$env:USERPROFILE -ChildPath "unix-pwsh\Microsoft.PowerShell_profile.ps1")) {
    . (Join-Path -Path `$env:USERPROFILE -ChildPath "unix-pwsh\Microsoft.PowerShell_profile.ps1")
} else {
    iex (iwr "$githubProfileUrl").Content
}
# END unix-pwsh v$blockVersion
"@

    # Read current profile content
    $currentContent = Get-Content -Path $profilePath -Raw

    # Remove any standalone occurrences of the block content
$currentContent = $currentContent -replace 'if\s*\(\s*Test-Path\s*\(\s*Join-Path\s*-Path\s*`?\$env:USERPROFILE\s*-ChildPath\s*"unix-pwsh\\Microsoft.PowerShell_profile\.ps1"\s*\)\s*\)\s*\{\s*\.?\s*\(\s*Join-Path\s*-Path\s*`?\$env:USERPROFILE\s*-ChildPath\s*"unix-pwsh\\Microsoft.PowerShell_profile\.ps1"\s*\)\s*\}\s*else\s*\{\s*iex\s*\(\s*iwr\s*".*?/Microsoft\.PowerShell_profile\.ps1"\s*\)\.Content\s*\}', ''
    # Check for existing block and its version
    if ($currentContent -match "# BEGIN unix-pwsh v(\d+\.\d+\.\d+)") {
        $existingVersion = $matches[1]
        if ($existingVersion -eq $blockVersion) {
            Write-Host "'unix-pwsh' block version $blockVersion is already up-to-date at $profilePath." -ForegroundColor Green
            return
        } else {
            # Remove the old block
            $currentContent = $currentContent -replace "# BEGIN unix-pwsh v$existingVersion.*?# END unix-pwsh v$existingVersion", ""
        }
    }

    # Append the updated profile block with start and end tags and version
    $currentContent | Set-Content -Path $profilePath
    Add-Content -Path $profilePath -Value $profileBlock
    Write-Host "PowerShell profile updated with 'unix-pwsh' block version $blockVersion at $profilePath." -ForegroundColor Yellow
}


function Initialize-DevEnv {
    $importedModuleCount = 0
    foreach ($module in $modules) {
        $isInstalled = Get-ConfigValue -Key $module.ConfigKey
        if ($isInstalled -ne "True") {
            Write-Host "Initializing $($module.Name) module..."
            Initialize-Module $module.Name
        } else {
            Import-Module $module.Name
            $importedModuleCount++
        }
    }
    if ($importedModuleCount = @($modules).Count) {
        New-Item -ItemType File -Path $xConfigPath | Out-Null
    }
    Write-Host "✅ Imported $importedModuleCount modules successfully." -ForegroundColor Green
    if ($ohmyposh_installed -ne "True") { 
        . Invoke-Expression (Invoke-WebRequest -Uri "$githubBaseURL/pwsh_helper.ps1" -UseBasicParsing).Content
        Test-ohmyposh 
    }
    $font_installed_var = "${font}_installed"
    if (((Get-Variable -Name $font_installed_var).Value) -ne "True") {
        . Invoke-Expression (Invoke-WebRequest -Uri "$githubBaseURL/pwsh_helper.ps1" -UseBasicParsing).Content
        Test-$font
    }
    if ((Test-Path Variable:vscode_installed) -and ($vscode_installed -ne "True")) {
        . Invoke-Expression (Invoke-WebRequest -Uri "$githubBaseURL/pwsh_helper.ps1" -UseBasicParsing).Content
        . Invoke-Expression (Invoke-WebRequest -Uri "$githubBaseURL/custom_functions.ps1" -UseBasicParsing).Content
        Test-vscode
    }  
    Test-sudo
    Write-Host "✅ Successfully initialized Pwsh with all modules and applications`n" -ForegroundColor Green
    wt.exe -p "PowerShell"
    . Invoke-Expression (Invoke-WebRequest -Uri "$githubBaseURL/pwsh_helper.ps1" -UseBasicParsing).Content
    $null = Show-MessageBox $infoMessage 'Important Notice' -Buttons OK -Icon Information
    $null = Show-MessageBox $infoMessage 'Important Notice' -Buttons OK -Icon Information
    # Remove the trust from PSGallery Repository
    Set-PSRepository -Name "PSGallery" -InstallationPolicy Untrusted
    exit
}


# Function to create config file
function Install-Config {
    if (-not (Test-Path -Path $configPath)) {
        # First we need to make sure the folder for the config file exists.
        $configDirectory = Split-Path -Path $configPath
        if (-not (Test-Path -Path $configDirectory)) {
        New-Item -ItemType Directory -Path $configDirectory -Force | Out-Null
        }
        # Now create the actual config file
        New-Item -ItemType File -Path $configPath | Out-Null
        Write-Host "Configuration file created at $configPath" -ForegroundColor Yellow
    } else {
        Write-Host "✅ Successfully loaded config file" -ForegroundColor Green
    }
    Initialize-Keys
    Initialize-DevEnv
}


# Function to set a value in the config file
function Set-ConfigValue {
    param (
        [string]$Key,
        [string]$Value
    )
    $config = @{}
    # Try to load the existing config file content
    if (Test-Path -Path $configPath) {
        $content = Get-Content $configPath -Raw
        if (-not [string]::IsNullOrEmpty($content)) {
            $config = $content | ConvertFrom-Yaml
        }
    }
    # Ensure $config is a hashtable
    if (-not $config) {
        $config = @{}
    }
    $config[$Key] = $Value
    $config | ConvertTo-Yaml | Set-Content $configPath
    # Write-Host "Set '$Key' to '$Value' in configuration file." -ForegroundColor Green
    Initialize-Keys
}


# Function to get a value from the config file
function Get-ConfigValue {
    param (
        [string]$Key
    )
    $config = @{}
    # Try to load the existing config file content
    if (Test-Path -Path $configPath) {
        $content = Get-Content $configPath -Raw
        if (-not [string]::IsNullOrEmpty($content)) {
            $config = $content | ConvertFrom-Yaml
        }
    }
    # Ensure $config is a hashtable
    if (-not $config) {
        $config = @{}
    }
    return $config[$Key]
}


function Initialize-Module {
    param (
        [string]$moduleName
    )
    # Check if the module is already installed
    $moduleInstalled = Get-Module -ListAvailable -Name $moduleName
    
    if ($null -eq $moduleInstalled) {
        # Proceed only if the module is not installed
        if ($global:canConnectToGitHub) {
            try {
                Install-Module -Name $moduleName -Scope CurrentUser -SkipPublisherCheck
                Set-ConfigValue -Key "${moduleName}_installed" -Value "True"
            } catch {
                Write-Error "❌ Failed to install module ${moduleName}: $_"
            }
        } else {
            Write-Host "❌ Skipping Module initialization check due to GitHub.com not responding within 1 second." -ForegroundColor Yellow
        }
    } else {
        # If the module is already installed, set the config value and import it
        Set-ConfigValue -Key "${moduleName}_installed" -Value "True"
        Import-Module -Name $moduleName
        Write-Host "✅ Module $moduleName is already installed. Importing..."
    }
}


function Initialize-Keys {
    $keys = "Terminal-Icons_installed", "Powershell-Yaml_installed", "PoshFunctions_installed", "${font}_installed", "vscode_installed", "ohmyposh_installed"
    foreach ($key in $keys) {
        $value = Get-ConfigValue -Key $key
        Set-Variable -Name $key -Value $value -Scope Global
    }
}


function Test-sudo {
    if (Test-CommandExists sudo) {
        Write-Host "✅ sudo is installed." -ForegroundColor Green
    } else {
        Write-Host "No sudo currently installed, would you like to install Gsudo by GerardoG (https://github.com/gerardog/gsudo)?" -ForegroundColor Yellow
        $installGsudo = Read-Host "Do you want to install Gsudo? (Y/N)"
        if ($installGsudo -eq 'Y' -or $installGsudo -eq 'y') {
            winget install gerardog.gsudo
            Write-Host "✅ Gsudo installed successfully." -ForegroundColor Green
        } else {
            Write-Host "❌ Gsudo installation skipped." -ForegroundColor Yellow
        }
    }
}
