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

## Components Installed 🛠️
- **Terminal-Icons Module**: UI enhancements with icons.
- **Powershell-Yaml**: YAML file configuration.
- **PoshFunctions**: Essential PowerShell functions.
- **FiraCode Nerd Font**: Stylish font for code readability.
- **Oh My Posh**: Customizable prompt themes.

## Configuration 📁
- Configuration file at: `~/pwsh_custom_config.yml` for centralized options and faster loading.

## Usage 🚀
1. Paste: `iex (iwr "https://raw.githubusercontent.com/CrazyWolf13/dotfiles/main/pwsh/Microsoft.PowerShell_profile.ps1").Content`.
2. Profile is automatically created and injected.
3. Edit profile with `notepad $PROFILE`.
4. Use `pwsh` instead of `powershell` in Windows Terminal.
5. Enjoy!

## Supported Linux Commands 🐧
Aliases and functions for common Linux commands:

- `sudo`, `cd`, `ls`, `dirs`, `sed`, `which`, `export`, `pgrep`, `grep`, `pkill`, `head`, `tail`, `unzip`, `du`, `ll`, `df`, `reboot`, `poweroff`, `cd...`, `cd....`, `md5`, `sha1`, `sha256`, `uptime`, `ssh-copy-key`, `explrestart`, `expl`, `Get-PubIP`, `Get-PrivIP`, `gitpush`, `ptw`.

## License 📜
This project is licensed under the [MIT License](LICENSE).

---

*Developed by CrazyWolf13 with ❤️*