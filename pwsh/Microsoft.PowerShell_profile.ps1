# Check internet access
# Use wmi as there is no timeout in pwsh  5.0 and generally slow.
$timeout = 1000 
$pingResult = Get-WmiObject -Query "Select * from Win32_PingStatus where Address='github.com' and Timeout=$timeout"
if ($pingResult.StatusCode -eq 0) {$canConnectToGitHub = $true} 
else {$canConnectToGitHub = $false}

# Define vars.
$baseDir = "$HOME\unix-pwsh"
$configPath = "$baseDir\pwsh_custom_config.yml"
$xConfigPath = "$baseDir\pwsh_full_custom_config.yml" # This file exists if the prompt is fully installed with all dependencies.
$githubUser = "CrazyWolf13" # Change this here if you forked the repository.
$name= "Tobias"
$promptColor = "DarkCyan" # Choose a color in which the hello text is colored; All Colors: Black, Blue, Cyan, DarkBlue, DarkCyan, DarkGray, DarkGreen, DarkMagenta, DarkRed, DarkYellow, Gray, Green, Magenta, Red, White, Yellow.
$OhMyPoshConfig = "https://raw.githubusercontent.com/$githubUser/dotfiles/main/pwsh/$OhMyPoshConfigFileName"
$OhMyPoshConfigFileName = "montys.omp.json"
$font="FiraCode" # Font-Display and variable Name, name the same as font_folder
$font_url = "https://github.com/ryanoasis/nerd-fonts/releases/download/v3.2.1/FiraCode.zip" # Put here the URL of the font file that should be installed
$fontFileName = "FiraCodeNerdFontMono-Regular.ttf" # Put here the font file that should be installed
$font_folder = "FiraCode" # Put here the name of the zip folder of the downloaded font, but without the .zip extension.

$modules = @( 
    # This is a list of modules that need to be imported / installed
    @{ Name = "Powershell-Yaml"; ConfigKey = "Powershell-Yaml_installed" },
    @{ Name = "Terminal-Icons"; ConfigKey = "Terminal-Icons_installed" },
    @{ Name = "PoshFunctions"; ConfigKey = "PoshFunctions_installed" }
)
$files = @("Microsoft.PowerShell_profile.ps1", "installer.ps1", "pwsh_helper.ps1", "custom_functions.ps1", "functions.ps1", $OhMyPoshConfigFileName)

# Message to tell the user what to do after installation
$infoMessage = @"
To fully utilize the custom Unix-pwsh profile, please follow these steps:
1. Set Windows Terminal as the default terminal.
2. Choose PowerShell Core as the preferred startup profile in Windows Terminal.
3. Go to Settings > Defaults > Appearance > Font and select the Nerd Font.

These steps are necessary to ensure the pwsh profile works as intended.
If you have further questions, on how to set the above, don't hesitate to ask me, by filing an issue on my repository, after you tried searching the web for yourself.
"@

$scriptBlock = {
    param($githubUser, $files, $baseDir, $canConnectToGitHub)
    Invoke-Expression (Invoke-WebRequest -Uri "https://raw.githubusercontent.com/$githubUser/dotfiles/main/pwsh/pwsh_helper.ps1" -UseBasicParsing).Content
    BackgroundTasks
}

# -----------------------------------------------------------------------------
# Functions
# -----------------------------------------------------------------------------

# Function for calling the update Powershell Script
function Run-UpdatePowershell {
    . Invoke-Expression (Invoke-WebRequest -Uri "https://raw.githubusercontent.com/$githubUser/dotfiles/main/pwsh/pwsh_helper.ps1" -UseBasicParsing).Content
    Update-Powershell
}

# ----------------------------------------------------------------------------

Write-Host ""
Write-Host "Welcome $name ⚡" -ForegroundColor $promptColor
Write-Host ""

# Function to check if all the $files exist or not.
$allFilesExist = $files | ForEach-Object { Join-Path -Path $baseDir -ChildPath $_ } | Test-Path -PathType Leaf -ErrorAction SilentlyContinue | ForEach-Object { $_ -eq $true }
if ($allFilesExist -contains $false) {
    $injectionMethod = "remote"
} else {
    $injectionMethod = "local"
    $OhMyPoshConfig = Join-Path -Path $baseDir -ChildPath $OhMyPoshConfigFileName
}

# Check for dependencies and if not chainload the installer.
if (Test-Path -Path $xConfigPath) {
    # Check if the Master config file exists, if so skip every other check.
    Write-Host "✅ Successfully initialized Pwsh`n" -ForegroundColor Green
    Import-Module Terminal-Icons
    # foreach ($module in $modules) {
    #     # As the master config exists, we assume that all modules are installed.
    #     Import-Module $module.Name
    # }
} else {
    # If there is no internet connection, we cannot install anything.
    if (-not $global:canConnectToGitHub) {
        Write-Host "❌ Skipping initialization due to GitHub not responding within 4 second." -ForegroundColor Red
        exit
    }
    . Invoke-Expression (Invoke-WebRequest -Uri "https://raw.githubusercontent.com/$githubUser/dotfiles/main/pwsh/installer.ps1" -UseBasicParsing).Content
    Install-NuGet
    Test-Pwsh 
    Test-CreateProfile
    Install-Config
}

# Try to import MS PowerToys WinGetCommandNotFound
Import-Module -Name Microsoft.WinGet.CommandNotFound > $null 2>&1
if (-not $?) { Write-Host "💭 Make sure to install WingetCommandNotFound by MS PowerToys" -ForegroundColor Yellow }

# Inject OhMyPosh
oh-my-posh init pwsh --config $OhMyPoshConfig | Invoke-Expression


# ----------------------------------------------------------
# Deferred loading
# Source: https://fsackur.github.io/2023/11/20/Deferred-profile-loading-for-better-performance/
# ----------------------------------------------------------

# Check if psVersion is lower than 7.x, then load the functions **without** deferred loading
if ($PSVersionTable.PSVersion.Major -lt 7) {
    if ($injectionMethod -eq "local") {
        . "$baseDir\custom_functions.ps1"
        . "$baseDir\functions.ps1"
        # Execute the background tasks
        Start-Job -ScriptBlock $scriptBlock -ArgumentList $githubUser, $files, $baseDir, $canConnectToGitHub
        } else {
        if ($global:canConnectToGitHub) {
            #Load Custom Functions
            . Invoke-Expression (Invoke-WebRequest -Uri "https://raw.githubusercontent.com/$githubUser/dotfiles/main/pwsh/custom_functions.ps1" -UseBasicParsing).Content
            #Load Functions
            . Invoke-Expression (Invoke-WebRequest -Uri "https://raw.githubusercontent.com/$githubUser/dotfiles/main/pwsh/functions.ps1" -UseBasicParsing).Content
            # Update PowerShell in the background
            Start-Job -ScriptBlock $scriptBlock -ArgumentList $githubUser, $files, $baseDir, $canConnectToGitHub
                } else {
            Write-Host "❌ Skipping initialization due to GitHub not responding within 1 second." -ForegroundColor Red
        }
    }
}

# ---------------------------------------------------------

$Deferred = {
    if ($injectionMethod -eq "local") {
        . "$baseDir\custom_functions.ps1"
        . "$baseDir\functions.ps1"
        # Execute the background tasks
        Start-Job -ScriptBlock $scriptBlock -ArgumentList $githubUser, $files, $baseDir, $canConnectToGitHub
        } else {
        if ($global:canConnectToGitHub) {
            #Load Custom Functions
            . Invoke-Expression (Invoke-WebRequest -Uri "https://raw.githubusercontent.com/$githubUser/dotfiles/main/pwsh/custom_functions.ps1" -UseBasicParsing).Content
            #Load Functions
            . Invoke-Expression (Invoke-WebRequest -Uri "https://raw.githubusercontent.com/$githubUser/dotfiles/main/pwsh/functions.ps1" -UseBasicParsing).Content
            # Update PowerShell in the background
            Start-Job -ScriptBlock $scriptBlock -ArgumentList $githubUser, $files, $baseDir, $canConnectToGitHub
            } else {
            Write-Host "❌ Skipping initialization due to GitHub not responding within 1 second." -ForegroundColor Red
        }
    }
}


$GlobalState = [psmoduleinfo]::new($false)
$GlobalState.SessionState = $ExecutionContext.SessionState
# to run our code asynchronously
$Runspace = [runspacefactory]::CreateRunspace($Host)
$Powershell = [powershell]::Create($Runspace)
$Runspace.Open()
$Runspace.SessionStateProxy.PSVariable.Set('GlobalState', $GlobalState)
# ArgumentCompleters are set on the ExecutionContext, not the SessionState
# Note that $ExecutionContext is not an ExecutionContext, it's an EngineIntrinsics 😡
$Private = [Reflection.BindingFlags]'Instance, NonPublic'
$ContextField = [Management.Automation.EngineIntrinsics].GetField('_context', $Private)
$Context = $ContextField.GetValue($ExecutionContext)
# Get the ArgumentCompleters. If null, initialise them.
$ContextCACProperty = $Context.GetType().GetProperty('CustomArgumentCompleters', $Private)
$ContextNACProperty = $Context.GetType().GetProperty('NativeArgumentCompleters', $Private)
$CAC = $ContextCACProperty.GetValue($Context)
$NAC = $ContextNACProperty.GetValue($Context)
if ($null -eq $CAC)
{
    $CAC = [Collections.Generic.Dictionary[string, scriptblock]]::new()
    $ContextCACProperty.SetValue($Context, $CAC)
}
if ($null -eq $NAC)
{
    $NAC = [Collections.Generic.Dictionary[string, scriptblock]]::new()
    $ContextNACProperty.SetValue($Context, $NAC)
}
# Get the AutomationEngine and ExecutionContext of the runspace
$RSEngineField = $Runspace.GetType().GetField('_engine', $Private)
$RSEngine = $RSEngineField.GetValue($Runspace)
$EngineContextField = $RSEngine.GetType().GetFields($Private) | Where-Object {$_.FieldType.Name -eq 'ExecutionContext'}
$RSContext = $EngineContextField.GetValue($RSEngine)
# Set the runspace to use the global ArgumentCompleters
$ContextCACProperty.SetValue($RSContext, $CAC)
$ContextNACProperty.SetValue($RSContext, $NAC)
$Wrapper = {
    # Without a sleep, you get issues:
    #   - occasional crashes
    #   - prompt not rendered
    #   - no highlighting
    # Assumption: this is related to PSReadLine.
    # 20ms seems to be enough on my machine, but let's be generous - this is non-blocking
    Start-Sleep -Milliseconds 100
    . $GlobalState {. $Deferred; Remove-Variable Deferred}
}
$null = $Powershell.AddScript($Wrapper.ToString()).BeginInvoke()
