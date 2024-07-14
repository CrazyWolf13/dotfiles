# Define vars.
$canConnectToGitHub = Test-Connection github.com -Count 1 -Quiet -TimeoutSeconds 1 # Check Internet and exit if it takes longer than 1 second
$configPath = "$HOME\pwsh_custom_config.yml"
$xConfigPath = "$HOME\pwsh_full_custom_config.yml" # This file exists if the prompt is fully installed with all dependencies.
$githubUser = "CrazyWolf13"
$name= "Tobias"
$promptColor = "DarkCyan" # Choose a color in which the hello text is colored; All Colors: Black, Blue, Cyan, DarkBlue, DarkCyan, DarkGray, DarkGreen, DarkMagenta, DarkRed, DarkYellow, Gray, Green, Magenta, Red, White, Yellow.
$OhMyPoshConfig = "https://raw.githubusercontent.com/$githubUser/dotfiles/main/customisation/montys.omp.json"
$font="FiraCode" # Font-Display and variable Name, name the same as font_folder
$font_url = "https://github.com/ryanoasis/nerd-fonts/releases/download/v3.2.1/FiraCode.zip" # Put here the URL of the font file that should be installed
$fontFileName = "FiraCodeNerdFontMono-Regular.ttf" # Put here the font file that should be installed
$font_folder = "FiraCode" # Put here the name of the zip folder, but without the .zip extension.
$modules = @( 
    # This is a list of modules that need to be imported / installed
    @{ Name = "Terminal-Icons"; ConfigKey = "Terminal-Icons_installed" },
    @{ Name = "Powershell-Yaml"; ConfigKey = "Powershell-Yaml_installed" },
    @{ Name = "PoshFunctions"; ConfigKey = "PoshFunctions_installed" }
)

# -----------------------------------------------------------------------------

if (-not $global:canConnectToGitHub) {
    Write-Host "❌ Skipping Dev-Environment initialization due to GitHub.com not responding within 1 second." -ForegroundColor Red
    exit
}

if (-not (Test-Path -Path $xConfigPath)) {
    # Check if the Master config file exists, if so skip every other check.
    Write-Host "✅ Successfully initialized Pwsh with all modules and applications`n" -ForegroundColor Green
    foreach ($module in $modules) {
        # As the master config exists, we assume that all modules are installed.
        Import-Module $module.Name
    }
} else {
    . Invoke-Expression (Invoke-WebRequest -Uri "https://raw.githubusercontent.com/$githubUser/dotfiles/main/pwsh/installer.ps1" -UseBasicParsing).Content
    Initialize-DevEnv
    Install-Config
}

function Run-UpdatePowershell {
    . Invoke-Expression (Invoke-WebRequest -Uri "https://raw.githubusercontent.com/$githubUser/dotfiles/main/pwsh/pwsh_helper.ps1" -UseBasicParsing).Content
    Update-Powershell
}

# -------------
# Run section

Write-Host ""
Write-Host "Welcome $name ⚡" -ForegroundColor $promptColor
Write-Host ""


# Try to import MS PowerToys WinGetCommandNotFound
Import-Module -Name Microsoft.WinGet.CommandNotFound > $null 2>&1
if (-not $?) { Write-Host "💭 Make sure to install WingetCommandNotFound by MS PowerToys" -ForegroundColor Yellow }

# Inject OhMyPosh
oh-my-posh init pwsh --config $OhMyPoshConfig | Invoke-Expression

# ----------------------------------------------------------
# Deferred loading
# ----------------------------------------------------------


$Deferred = {
    #Load Custom Functions
    . Invoke-Expression (Invoke-WebRequest -Uri "https://raw.githubusercontent.com/$githubUser/dotfiles/main/pwsh/custom_functions.ps1" -UseBasicParsing).Content
    #Load Functions
    . Invoke-Expression (Invoke-WebRequest -Uri "https://raw.githubusercontent.com/$githubUser/dotfiles/main/pwsh/functions.ps1" -UseBasicParsing).Content
    # Update PowerShell in the background
    Start-Job -ScriptBlock {
        Write-Host "⚡ Invoking Helper-Script" -ForegroundColor Yellow
        . Invoke-Expression (Invoke-WebRequest -Uri "https://raw.githubusercontent.com/$githubUser/dotfiles/main/pwsh/pwsh_helper.ps1" -UseBasicParsing).Content
        Update-PowerShell 
    } > $null 2>&1
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
