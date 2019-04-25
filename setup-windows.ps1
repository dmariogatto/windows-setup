#Requires -RunAsAdministrator

param (
    [Parameter(Mandatory = $true,
        HelpMessage = "Enter the path of the registry values CSV file.")][string]$RegValuesCsvPath,
    [Parameter(Mandatory = $true,
        HelpMessage = "Enter the path of the choco packages CSV file.")][string]$ChocoPackagesCsvPath,
    [Parameter(Mandatory = $true,
        HelpMessage = "For realsies?")][bool]$ForRealsies
)

if ($ForRealsies) {
    Set-TimeZone -Name "Cen. Australia Standard Time"
}

# Set Registry Entries
Import-Csv $RegValuesCsvPath -delimiter '|' |
ForEach-Object {
    if ($_.Path -and $_.Name -and $_.Value -and $_.Type) {
        $registryPath = $_.Path
        $name = $_.Name
        $val = $_.Value
        $type = $_.Type
        
        if (!(Test-Path $registryPath) -and $ForRealsies) { 
            New-Item -Path $registryPath -Force | Out-Null 
        }

        if ($ForRealsies) {
            New-ItemProperty -Path $registryPath -Name $name -Value $val -PropertyType $type -Force | Out-Null
        }
        
        if ($_.Description) {
            Write-Host $_.Description
        }
        else {
            Write-Host "Updated $registryPath\$name with value '$val'"
        }
    }    
}

# Restart Explorer 💣
if ($ForRealsies) {
    Stop-Process -ProcessName explorer
}

# Choco Time 🍫
if (Get-Command "choco" -errorAction SilentlyContinue) {
    Write-Host "Checking for Chocolatey update..."
    if ($ForRealsies) {
        choco upgrade chocolatey -y
        choco feature enable --name=useRememberedArgumentsForUpgrades
    }
}
else {
    Write-Host "Installing Chocolatey..."
    if ($ForRealsies) {
        Set-ExecutionPolicy Bypass -Scope Process -Force; Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
        choco feature enable --name=useRememberedArgumentsForUpgrades
    }
}

Import-Csv $ChocoPackagesCsvPath -delimiter '|' |
ForEach-Object {
    if ($_.Package) {
        $packName = $_.Package
        if ($_.Parameters) { 
            $params = $_.Parameters
            if ($ForRealsies) {
                choco install $packName $params -y
            }
            else {
                Write-Host "choco install $packName $params -y"
            }
        }
        else { 
            if ($ForRealsies) {
                choco install $packName -y
            }
            else {
                Write-Host "choco install $packName -y"
            }
        }
    }    
}
