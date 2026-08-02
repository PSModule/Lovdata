#Requires -Modules @{ ModuleName = 'Pester'; ModuleVersion = '6.0.0'; MaximumVersion = '6.*' }

<#
    .SYNOPSIS
    Shared setup for the Lovdata test suites.

    .DESCRIPTION
    Points the imported Lovdata module at a throwaway Context vault so tests exercise the real store
    without touching the vault a developer or runner already has, and returns the vault name so the
    calling suite can remove it again.

    .EXAMPLE
    $vault = . "$PSScriptRoot/Lovdata.TestSetup.ps1"

    .INPUTS
    None

    .OUTPUTS
    System.String
#>
[CmdletBinding()]
param()

$testVault = "PSModule.Lovdata.Tests.$([guid]::NewGuid().Guid)"

InModuleScope -ModuleName Lovdata -Parameters @{ Vault = $testVault } -ScriptBlock {
    param($Vault)

    $script:Lovdata.ContextVault = $Vault
    $script:Lovdata.Config = $null
}

$testVault
