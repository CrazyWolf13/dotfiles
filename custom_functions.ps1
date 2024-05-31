Set-Alias n notepad
Set-Alias vs code

function explrestart {taskkill /F /IM explorer.exe; Start-Process explorer.exe}
function expl { explorer . }
function Get-PubIP { (Invoke-WebRequest http://ifconfig.me/ip).Content }
function Get-PrivIP { (Get-NetIPAddress | Where-Object -Property AddressFamily -EQ -Value "IPv4").IPAddress }

# Folder shortcuts
function cdgit {Set-Location "G:\Informatik\Projekte"}
function cdtbz {Set-Location "$env:OneDriveCommercial\Dokumente\Daten\TBZ"}
function cdbmz {Set-Location "$env:OneDriveCommercial\Dokumente\Daten\BMZ"}
function cdhalter {Set-Location "$env:OneDriveCommercial\Dokumente\Daten\Halter"}

function gitpush {
    git pull
    git add .
    git commit -m "$args"
    git push
}

function ssh-m122 {
    param ([string]$ip)
    ssh -i ~\.ssh\06-student.pem -o ServerAliveInterval=30 "ubuntu@$ip"
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