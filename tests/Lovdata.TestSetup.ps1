#Requires -Modules @{ ModuleName = 'Pester'; ModuleVersion = '6.0.0'; MaximumVersion = '6.*' }

<#
    .SYNOPSIS
    Shared setup for the Lovdata test suites.

    .DESCRIPTION
    Resets the imported Lovdata module's in-memory settings back to the module defaults so each suite
    starts from a known state. The module keeps no vault and no secret, so there is nothing to clean up
    afterwards.

    .EXAMPLE
    . "$PSScriptRoot/Lovdata.TestSetup.ps1"

    .INPUTS
    None

    .OUTPUTS
    None
#>
[CmdletBinding()]
param()

InModuleScope -ModuleName Lovdata {
    $script:Lovdata.Config = $null
}
