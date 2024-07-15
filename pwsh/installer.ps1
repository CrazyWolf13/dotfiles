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

function Test-Pwsh {
    if (-not (Get-Command pwsh -ErrorAction SilentlyContinue)) {
        Write-Host "PowerShell Core (pwsh) is not installed. Starting the update..." -ForegroundColor Yellow
        Run-UpdatePowershell
        Start-Sleep -Seconds 8 # Wait for the update to finish
        Write-Host "Restarting the installation script with Powershell Core" -ForegroundColor Green
        Start-Process pwsh -ArgumentList "-NoExit", "-Command Invoke-Expression (Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/$githubUser/dotfiles/main/pwsh/installer.ps1'-UseBasicParsing).Content  ; Initialize-DevEnv ; Install-Config"
    }
}

function Test-CreateProfile {
    # Create $PATH folder if not exists.
    if (-not (Test-Path -Path (Split-Path -Path $PROFILE -Parent))) {
        New-Item -ItemType Directory -Path (Split-Path -Path $PROFILE -Parent) -Force | Out-Null
    }
    # Create profile if not exists
    if (-not (Test-Path -Path $PROFILE)) {
        New-Item -ItemType File -Path $PROFILE | Out-Null
        Add-Content -Path $PROFILE -Value "iex (iwr `https://raw.githubusercontent.com/$githubUser/dotfiles/main/pwsh/Microsoft.PowerShell_profile.ps1`).Content"
        Write-Host "PowerShell profile created at $PROFILE." -ForegroundColor Yellow
    }
}

function Initialize-DevEnv {
    $importedModuleCount = 0
    foreach ($module in $modules) {
        $isInstalled = Get-ConfigValue -Key $module.ConfigKey
        if ($isInstalled -ne "True") {
            Write-Host "Initializing $($module.Name) module..."
            Initialize-Module $module.Name
            if (module.Name -eq "PowershellYaml") {
                # Check if we can already use ConvertTo-Yaml
                if (-not (Test-CommandExists ConvertTo-Yaml)) {
                    Write-Host "Restarting installer to make Powershell-Yaml available." -ForegroundColor Yellow
                    Start-Process pwsh -ArgumentList "-NoExit", "-Command Invoke-Expression (Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/$githubUser/dotfiles/main/pwsh/installer.ps1'-UseBasicParsing).Content  ; Initialize-DevEnv ; Install-Config"
                    exit
                }
            }
        } else {
            Import-Module $module.Name
            $importedModuleCount++
        }
    }
    if ($importedModuleCount = @($modules).Count) {
        New-Item -ItemType File -Path $xConfigPath
    }
    Write-Host "✅ Imported $importedModuleCount modules successfully." -ForegroundColor Green
    if ($ohmyposh_installed -ne "True") { 
        Write-Host "⚡ Invoking Helper-Script" -ForegroundColor Yellow
        . Invoke-Expression (Invoke-WebRequest -Uri "https://raw.githubusercontent.com/$githubUser/dotfiles/main/pwsh/pwsh_helper.ps1" -UseBasicParsing).Content
        Test-ohmyposh 
        }
        $font_installed_var = "${font}_installed"
    if (((Get-Variable -Name $font_installed_var).Value) -ne "True") {
        Write-Host "⚡ Invoking helper-script" -ForegroundColor Yellow
        . Invoke-Expression (Invoke-WebRequest -Uri "https://raw.githubusercontent.com/$githubUser/dotfiles/main/pwsh/pwsh_helper.ps1" -UseBasicParsing).Content
        Test-$font
        }
    if ($vscode_installed -ne "True") { 
        Write-Host "⚡ Invoking Custom_Functions-Script" -ForegroundColor Yellow
        . Invoke-Expression (Invoke-WebRequest -Uri "https://raw.githubusercontent.com/$githubUser/dotfiles/main/pwsh/pwsh_helper.ps1" -UseBasicParsing).Content
        . Invoke-Expression (Invoke-WebRequest -Uri "https://raw.githubusercontent.com/$githubUser/dotfiles/main/pwsh/custom_functions.ps1" -UseBasicParsing).Content
        Test-vscode 
        }
    
    Write-Host "✅ Successfully initialized Pwsh with all modules and applications`n" -ForegroundColor Green
}

# Function to create config file
function Install-Config {
    if (-not (Test-Path -Path $configPath)) {
        New-Item -ItemType File -Path $configPath | Out-Null
        Write-Host "Configuration file created at $configPath ❗" -ForegroundColor Yellow
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
}

function Initialize-Keys {
    $keys = "Terminal-Icons_installed", "Powershell-Yaml_installed", "PoshFunctions_installed", "${font}_installed", "vscode_installed", "ohmyposh_installed"
    foreach ($key in $keys) {
        $value = Get-ConfigValue -Key $key
        Set-Variable -Name $key -Value $value -Scope Global
    }
}
