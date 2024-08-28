Set-Alias n notepad
Set-Alias vs code

function explrestart {taskkill /F /IM explorer.exe; Start-Process explorer.exe}
function expl { explorer . }
function Get-PubIP { (Invoke-WebRequest http://ifconfig.me/ip).Content }
function Get-PrivIP { (Get-NetIPAddress | Where-Object -Property AddressFamily -EQ -Value "IPv4").IPAddress }

# Folder shortcuts
function cdgit {Set-Location "G:\Informatik\Projekte"}

if (Test-Path "HKCU:\SOFTWARE\Microsoft\OneDrive\Accounts\Business1") {
    $onedriveProperty = Get-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\OneDrive\Accounts\Business1"
    if ($onedriveProperty -and $onedriveProperty.UserFolder) {
        $onedrive_Path = $onedriveProperty.UserFolder }
    function cdtbz {Set-Location "$onedrive_Path\Dokumente\Daten\TBZ"}
    function cdbmz {Set-Location "$onedrive_Path\Dokumente\Daten\BMZ"}
    function cdhalter {Set-Location "$onedrive_Path\Dokumente\Daten\Halter"}
}


function gitpush {
    git pull
    git add .
    git commit -m "$args"
    git push
}

# Send any file/pipe or text to the Wastebin(Pastebin alternative) Server
function Send-Wastebin {
    [CmdletBinding()]
    param (
        [Parameter(Position=0, ValueFromPipeline=$true, Mandatory=$false)]
        [string[]]$Content,

        [Parameter(Position=1)]
        [int]$ExpirationTime = 3600,

        [Parameter(Position=2)]
        [bool]$BurnAfterReading = $false,

        [Parameter(Position=3)]
        [switch]$Help
    )
    begin {
        if ($Help) {
            Write-Host "Use this to send a message to the Wastebin Server."
            Write-Host "Make sure to replace the encoded url below with your own url." 
            Write-Host "If you need help, don't hesitate to create an issue on my GitHub repository (CrazyWolf13/unix-pwsh) :)"
            Write-Host "example: ptw This is a test message"
            Write-Host "example: ptw 'C:\path\to\file.txt' -ExpirationTime 3600 -BurnAfterReading"
            Write-Host "example: echo 'Hello World!' | ptw"
            return
        }
        $WastebinServerUrl = [System.Text.Encoding]::UTF8.GetString([Convert]::FromBase64String("aHR0cHM6Ly9iaW4uY3Jhenl3b2xmLmRldg=="))
        $Payload = @{
            text = ""
            extension = $null
            expires = $ExpirationTime
            burn_after_reading = $BurnAfterReading
        }
    }
    process {
        if (-not $Help) {
            foreach ($line in $Content) {
                if (Test-Path $line -PathType Leaf) {
                    $Payload.text += (Get-Content $line -Raw) + "`n"
                } else {
                    $Payload.text += $line + "`n"
                }
            }
        }
    }
    end {
        if (-not $Help) {
            $Payload.text = $Payload.text.TrimEnd("`n")
            $jsonPayload = $Payload | ConvertTo-Json
            
            try {
                $Response = Invoke-RestMethod -Uri $WastebinServerUrl -Method Post -Body $jsonPayload -ContentType 'application/json'
                $Path = $Response.path -replace '\.\w+$', ''
                Write-Host ""
                Write-Host "$WastebinServerUrl$Path"
            }
            catch {
                Write-Host "Error occurred: $_"
            }
        }
    }
}
Set-Alias -Name ptw -Value Send-Wastebin

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

function top {
   if ($host -and $host.UI.SupportsVirtualTerminal) {
        Clear-Host
        $lines = $Host.UI.RawUI.WindowSize.Height
        $cols = $Host.UI.RawUI.WindowSize.Width
        [int]$min = 10
        $topCount = ($lines - $min)
        if ($lines -le $min) {
            $topCount = $lines 
        }
        $sortDesc = 'CPU'
        $pp = $ProgressPreference
        $ProgressPreference = "SilentlyContinue"
        try {
            while (1) {
                $info = get-computerinfo
                $pInuse = $info.OsTotalVisibleMemorySize - $info.OsFreePhysicalMemory
                $phys = [math]::round(($info.OsTotalVisibleMemorySize/1MB),2)
                $physuse = ($pInuse/$info.OsTotalVisibleMemorySize).toString("P")
                $cpuAv = (Get-CimInstance -ClassName win32_processor | Measure-Object -Property LoadPercentage -Average).Average
                write-host "system: $($info.CsCaption) uptime: $($info.OsUptime) OS version $($info.OsVersion) $($info.OSDisplayVersion)"
                write-host "process: $($info.OsNumberOfProcesses) users: $($info.OsNumberOfUsers) Sort: $($sortDesc.PadRight(7))"
                write-host "cpus: $($info.CsNumberOfLogicalProcessors) load: $($cpuAv)% Physical memory: $phys usage: $physUse"
                Get-Process | Sort-Object -desc $sortDesc | Select-Object -first $topCount | format-table 
                # if ($host.UI.RawUI.KeyAvailable) # doesn't work?
                if ([Console]::KeyAvailable)
                {
                    $key = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
                    switch ($key.character) {
                        'c'{
                            $sortDesc = 'CPU'
                        }
                        'h' {
                            $sortDesc = 'Handles'
                        }
                        'n'{
                            $sortDesc = 'NPM'
                        }
                        'p' {
                            $sortDesc = 'PM'
                        }
                        'q'{
                            Clear-Host
                            return
                        }
                        'w'{
                            $sortDesc = 'WS'
                        }
                    }
                }
                else {                    
                    Start-Sleep 0.5
                }
                if (($Host.UI.RawUI.WindowSize.Height -ne $lines) -or 
                ($Host.UI.RawUI.WindowSize.Width -ne $cols)) {
                    Clear-Host
                    $lines = $Host.UI.RawUI.WindowSize.Height
                    $cols = $Host.UI.RawUI.WindowSize.Width
                    $topCount = ($lines - $min)
                    if ($lines -le $min) {
                        $topCount = $lines 
                    }
                }
                $host.UI.RawUI.CursorPosition = @{x = 0; y = 0}
            }
        }
        finally {
            $ProgressPreference = $pp 
        }
    }
}
