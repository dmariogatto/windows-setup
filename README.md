# Windows 10 Initialisation Script

A simple PowerShell script that takes in two CSV files. One contains registry values that will be created or modified. The other a list of [Chocolately](https://chocolatey.org/) packages and any optional parameters that will be installed.

Both CSV files use '|' as the delimiter, as there are cases where commas are needed in the values.

The registry values CSV has the form:

- __Path:__ the path to the registry key
- __Name:__ the name of the registry key to be created/modified
- __Value:__ the new value of the registry key (strings should be surrounded by quotes & hex values prefixed by _0x_)
- __Type:__  the registry entry data key (Binary, DWord, ExpandString, MultiString, QWord or String)
- __Description:__ free text describing what the entry does

The Chocolately packages CSV has the form:

- __Package:__ the name of the choco package to install
- __Parameters:__ any optional choco install command arguments

The script needs to be run as an administrator and will check for Chocolately, if not found it will be installed, otherwise, an update will be requested.

## Script Parameters

- __[string]RegValsPath:__ the path to the registry values CSV file
- __[switch]CommitReg__ if set the registry will be modified
- __[string]ChocoPackagesPath__ the path to the choco packages CSV file
- __[switch]CommitChoco__ if set the choco packages will be installed