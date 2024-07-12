# nilesoft-shell
Repository containing my nilesoft shell config.

Use following commands to set up nilesoft shell, after installing it:

````
git clone https://github.com/crazywolf13/dotfiles.git

$sourceDir = ".\dotfiles\customisation\nilesoftShell"
$destDir = "C:\Program Files\Nilesoft Shell"

# Make sure dest exists
if (-Not (Test-Path -Path $destDir)) {
    New-Item -ItemType Directory -Path $destDir -Force
}

# Copy files with force
Get-ChildItem -Path $sourceDir -Recurse | ForEach-Object {
    $destPath = Join-Path -Path $destDir -ChildPath $_.FullName.Substring($sourceDir.Length)
    if ($_.PSIsContainer) {
        # Create directory if it does not exist
        if (-Not (Test-Path -Path $destPath)) {
            New-Item -ItemType Directory -Path $destPath -Force
        }
    } else {
        # Copy file and overwrite if it exists
        Copy-Item -Path $_.FullName -Destination $destPath -Force
    }
}
````
