
# Functions to mimic some of the functionality of the Unix shell
# Does the the rough equivalent of dir /s /b. For example, dirs *.png is dir /s /b *.png
function dirs {
    if ($args.Count -gt 0) {
        Get-ChildItem -Recurse -Include "$args" | Foreach-Object FullName
    } else {
        Get-ChildItem -Recurse | Foreach-Object FullName
    }
}

function sed($file, $find, $replace) {
    (Get-Content $file).replace("$find", $replace) | Set-Content $file
}

function which($name) {
    Get-Command $name | Select-Object -ExpandProperty Definition
}

function export($name, $value) {
    set-item -force -path "env:$name" -value $value;
}

function pgrep($name) {
    Get-Process $name
}

function grep {
    param (
        [string]$regex,
        [string]$dir
    )
    process {
        if ($dir) {
            Get-ChildItem -Path $dir -Recurse -File | Select-String -Pattern $regex
        } else {     # Use if piped input is provided
            $input | Select-String -Pattern $regex
        }
    }
}

function pkill {
    param (
        [string]$name
    )
    process {
        if ($name) {
            Get-Process $name -ErrorAction SilentlyContinue | Stop-Process
        } else {
            $input | ForEach-Object { Get-Process $_ -ErrorAction SilentlyContinue | Stop-Process }
        }
    }
}

function head {
    param (
        [string]$Path,
        [int]$n = 10
    )
    process {
        if ($Path) {
            Get-Content $Path -Head $n
        } else {
            $input | Select-Object -First $n
        }
    }
}

function tail {
    param (
        [string]$Path,
        [int]$n = 10
    )
    process {
        if ($Path) {
            Get-Content $Path -Tail $n
        } else {
            $input | Select-Object -Last $n
        }
    }
}

# Unzip function
function unzip {
    param (
        [string]$file
    )
    process {
        if ($file) {
            $fullPath = Join-Path -Path $pwd -ChildPath $file
            if (Test-Path $fullPath) {
                Write-Output "Extracting $file to $pwd"
                Expand-Archive -Path $fullPath -DestinationPath $pwd
            } else {
                Write-Output "File $file does not exist in the current directory"
            }
        } else {
            $input | ForEach-Object {
                $fullPath = Join-Path -Path $pwd -ChildPath $_
                if (Test-Path $fullPath) {
                    Write-Output "Extracting $_ to $pwd"
                    Expand-Archive -Path $fullPath -DestinationPath $pwd
                } else {
                    Write-Output "File $_ does not exist in the current directory"
                }
            }
        }
    }
}

function du {
    param (
        [string]$Path = (Get-Location)
    )
    try {
        # Get all items recursively at the specified path.
        $items = Get-ChildItem -Path $Path -Recurse -ErrorAction SilentlyContinue
        # Separate files and directories
        $files = $items | Where-Object { -not $_.PSIsContainer }
        $directories = $items | Where-Object { $_.PSIsContainer }
        # Measure properties
        $fileCount = $files.Count
        $directoryCount = $directories.Count
        $totalBytes = ($files | Measure-Object -Property Length -Sum).Sum
        # Convert bytes to a human-readable format
        if ($totalBytes -ge 1TB) {
            $size = "{0:N2} TB" -f ($totalBytes / 1TB)
        } elseif ($totalBytes -ge 1GB) {
            $size = "{0:N2} GB" -f ($totalBytes / 1GB)
        } elseif ($totalBytes -ge 1MB) {
            $size = "{0:N2} MB" -f ($totalBytes / 1MB)
        } elseif ($totalBytes -ge 1KB) {
            $size = "{0:N2} KB" -f ($totalBytes / 1KB)
        } else {
            $size = "{0:N2} bytes" -f $totalBytes
        }
        # Output results
        Write-Output "Directory Count : $directoryCount"
        Write-Output "File Count      : $fileCount"
        Write-Output "Total Size      : $size"
    } catch {
        Write-Output "An error occurred: $_"
    }
}

# Short ulities
function ll { Get-ChildItem -Path $pwd -File }
function df {get-volume}

# Aliases for reboot and poweroff
function Reboot-System {Restart-Computer -Force}
Set-Alias reboot Reboot-System
function Poweroff-System {Stop-Computer -Force}
Set-Alias poweroff Poweroff-System

# Useful file-management functions
function cd... { Set-Location ..\.. }
function cd.... { Set-Location ..\..\.. }

# Function to run a command or shell as admin.
function admin {
    if ($args.Count -gt 0) {   
        $argList = "& '" + $args + "'"
        Start-Process "wt.exe" -Verb runAs -ArgumentList $argList
    } else {
        Start-Process "wt.exe" -Verb runAs
    }
}
Set-Alias -Name sudo -Value admin

# Hash functions
function md5 {
    param (
        [string]$Path
    )
    process {
        if ($Path) {
            Get-FileHash -Algorithm MD5 $Path
        } else {
            $input | ForEach-Object { Get-FileHash -Algorithm MD5 $_ }
        }
    }
}

function sha1 {
    param (
        [string]$Path
    )
    process {
        if ($Path) {
            Get-FileHash -Algorithm SHA1 $Path
        } else {
            $input | ForEach-Object { Get-FileHash -Algorithm SHA1 $_ }
        }
    }
}

function sha256 {
    param (
        [string]$Path
    )
    process {
        if ($Path) {
            Get-FileHash -Algorithm SHA256 $Path
        } else {
            $input | ForEach-Object { Get-FileHash -Algorithm SHA256 $_ }
        }
    }
}

# Display system uptime
function uptime {
    if ($PSVersionTable.PSVersion.Major -eq 5) {
        $lastBootUpTime = Get-WmiObject win32_operatingsystem | Select-Object @{Name='LastBootUpTime'; Expression={$_.ConverttoDateTime($_.lastbootuptime)}}
        $uptime = (Get-Date) - $lastBootUpTime.LastBootUpTime
    } else {
        $since = net statistics workstation | Select-String "since" | ForEach-Object { $_.ToString().Replace('Statistics since ', '') }
        $lastBootUpTime = [DateTime]::ParseExact($since, "M/d/yyyy h:mm:ss AM/PM", [Globalization.CultureInfo]::InvariantCulture)
        $uptime = (Get-Date) - $lastBootUpTime
    }
    return "Online since $($uptime.Days) days, $($uptime.Hours) hours, $($uptime.Minutes) minutes"
}



function ssh-copy-key {
    param(
        [parameter(Position=0)]
        [string]$user,

        [parameter(Position=1)]
        [string]$ip
    )
    $pubKeyPath = "~\.ssh\id_ed25519.pub"
    $sshCommand = "cat $pubKeyPath | ssh $user@$ip 'cat >> ~/.ssh/authorized_keys'"
    Invoke-Expression $sshCommand
}