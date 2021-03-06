#Requires -RunAsAdministrator

param (
    [Parameter(HelpMessage = "Enter the path of the registry values CSV file.")][string]$RegValsPath,
    [Parameter(HelpMessage = "Commit registry changes")][switch]$CommitReg,
    [Parameter(HelpMessage = "Enter the path of the choco packages CSV file.")][string]$ChocoPackagesPath,
    [Parameter(HelpMessage = "Install choco packages")][switch]$CommitChoco
)

Set-TimeZone -Name "Cen. Australia Standard Time"

# Set Registry Entries
if ($RegValsPath -and (Test-Path $RegValsPath)) {
    Import-Csv $RegValsPath -Delimiter '|' |
    ForEach-Object {
        if ($_.Path -and $_.Name -and $_.Value -and $_.Type) {
            $registryPath = $_.Path
            $name = $_.Name
            $val = $_.Value
            $type = $_.Type

            if ($CommitReg) {
                if (!(Test-Path $registryPath)) { 
                    New-Item -Path $registryPath -Force | Out-Null
                }
                
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
    if ($CommitReg) {
        Stop-Process -ProcessName explorer
    }
}
else {
    Write-Host "Skipping regedit..."
}

# Choco Time 🍫
if ($ChocoPackagesPath -and (Test-Path $ChocoPackagesPath)) {
    $chocoInstalled = Get-Command "choco" -errorAction SilentlyContinue

    if ($CommitChoco) {
        if ($chocoInstalled) {
            Write-Host "Chocolatey installation found..."
            $currentVer = New-Object System.Version(choco -v)       
            $requiredVer = New-Object System.Version("0.10.4")    
            if ($currentVer -lt $requiredVer) {
                Write-Host "Chocolatey version $requiredVer or greater required, triggering update..."
                choco upgrade chocolatey -y
            }
        }
        else {
            Write-Host "Installing Chocolatey..."
            Set-ExecutionPolicy Bypass -Scope Process -Force; Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
        }

        choco feature enable --name=useRememberedArgumentsForUpgrades
    }   

    $installedPackages = @{ };
    choco list --lo -r | ConvertFrom-Csv -Header Package, Version -Delimiter '|' |
    ForEach-Object {
        if ($_.Package) {
            $installedPackages[$_.Package] = $_.Version
        }    
    }

    $chocoInstallCmds = @();
    Import-Csv $ChocoPackagesPath -Delimiter '|' |
    ForEach-Object {
        if ($_.Package) {
            $packName = $_.Package
            $params = $_.Parameters

            $currentVersion = $installedPackages[$packName]
            if ($currentVersion) {
                Write-Host "Package $packName ($currentVersion) is already installed, skipping install..."                
            }
            else {
                $installArgs = if ($params) { "$packName $params -y" } else { "$packName -y" }
                $chocoCommand = "choco install $installArgs -r"
                $chocoInstallCmds += $chocoCommand
            }           
        }    
    }

    $chocoInstallCmds |
    ForEach-Object {
        if ($CommitChoco) {
            Write-Host $_
            Invoke-Expression $_
        }
        else {
            Write-Host $_
        }
    }
}
else {
    Write-Host "Skipping choco..."
}

