# Contents
- [Contents](#contents)
- [Private PowerShell Configuration 🖥️](#private-powershell-configuration-️)
  - [TL:DR](#tldr)
  - [Features 🌟](#features-)
  - [Components Installed 🛠️](#components-installed-️)
  - [Configuration 📁](#configuration-)
  - [Usage 🚀](#usage-)
  - [Supported Linux Commands 🐧](#supported-linux-commands-)
  - [License 📜](#license-)


----

# Private PowerShell Configuration 🖥️

Thanks for the interest in my personal pwsh profile for linux-like feeling on windows powershell.
**This is my private repo, intended for myself only.**
But I'm maintaining a public version as well, which is basically the same.

You can find it here: [https://github.com/CrazyWolf13/unix-pwsh](https://github.com/CrazyWolf13/unix-pwsh)

## TL:DR
- Paste this into your PowerShell and then into your $PROFILE using `notepad $PROFILE`:
```bash
iex (iwr "https://raw.githubusercontent.com/CrazyWolf13/dotfiles/main/pwsh/Microsoft.PowerShell_profile.ps1").Content
```

## Features 🌟
- **Bash-like Shell Experience**: Mimics Unix shell functionality.
- **Oh My Posh Integration**: Stylish prompts and Git status indicators.
- **Deferred Loading**: Faster function loading.
- **Automatic Installation**: Installs necessary modules on first execution.
- **Local Caching**: Automatically downloads and updates the neccessary files into `$Home\unix-pwsh` to load faster and even while being offline.

## Components Installed 🛠️
- **Terminal-Icons Module**: UI enhancements with icons.
- **Powershell-Yaml**: YAML file configuration.
- **PoshFunctions**: Essential PowerShell functions.
- **NuGet**: Essential for installing the Pwsh Modules
- **FiraCode Nerd Font**: Stylish font for code readability.
- **Oh My Posh**: Customizable prompt themes.

## Configuration 📁
- Configuration file at: `~/unix-pwsh/pwsh_custom_config.yml` for faster loading.

## Usage 🚀
1. Paste: `iex (iwr "https://raw.githubusercontent.com/CrazyWolf13/dotfiles/main/pwsh/Microsoft.PowerShell_profile.ps1").Content`.
2. Profile is automatically created and injected, if not paste the below code, by editing profile-file with `notepad $PROFILE`.

>```powershell
> if (Test-Path (Join-Path -Path $env:USERPROFILE -ChildPath "unix-pwsh\Microsoft.PowerShell_profile.ps1")) { . (Join-Path -Path $env:USERPROFILE -ChildPath "unix-pwsh\Microsoft.PowerShell_profile.ps1") } else { iex (iwr "https://raw.githubusercontent.com/CrazyWolf13/dotfiles/main/Microsoft.PowerShell_profile.ps1").Content }
>```

3. Use `pwsh(Powershell Core) (Powershell 7.x +) (Powershell)` instead of `Microsoft Powershell` in Windows Terminal.
4. Enjoy!

## Supported Linux Commands 🐧
Aliases and functions for common Linux commands:

- `cd`, `ls`, `dirs`, `sed`, `which`, `export`, `pgrep`, `grep`, `pkill`, `head`, `tail`, `unzip`, `du`, `ll`, `df`, `reboot`, `poweroff`, `cd...`, `cd....`, `md5`, `sha1`, `sha256`, `uptime`, `ssh-copy-key`, `explrestart`, `expl`, `Get-PubIP`, `Get-PrivIP`, `gitpush`, `ptw`.

## License 📜
This project is licensed under the [MIT License](LICENSE).

---

*Developed by CrazyWolf13 with ❤️*