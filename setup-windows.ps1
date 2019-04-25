#Requires -RunAsAdministrator

param (
    [Parameter(Mandatory = $true,
        HelpMessage = "Enter the path of the registry value CSV file.")][string]$RegValueCsvPath
)

Import-Csv $RegValueCsvPath |
ForEach-Object {
    if ($_.Path -and $_.Name -and $_.Value -and $_.Type) {
        $registryPath = $_.Path
        $name = $_.Name
        $val = $_.Value
        $type = $_.Type
        
        if (!(Test-Path $registryPath)) { New-Item -Path $registryPath -Force | Out-Null }
        New-ItemProperty -Path $registryPath -Name $name -Value $val -PropertyType $type -Force | Out-Null
        if ($_.Description) { Write-Host $_.Description }
        else { Write-Host "Updated $registryPath\$name with value '$val'" }
    }    
}