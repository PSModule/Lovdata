#Requires -Modules @{ ModuleName = 'Context'; ModuleVersion = '8.1.6' }

function Initialize-LovdataConfig {
    <#
        .SYNOPSIS
        Load the Lovdata module configuration into memory.

        .DESCRIPTION
        Reads the module-scoped configuration context from the Lovdata vault and caches it for the rest
        of the session. The context is created from the module defaults the first time it is needed, and
        settings that were added to the module after the context was stored are backfilled from those
        defaults so an upgraded module never reads a half-populated configuration.

        .EXAMPLE
        Initialize-LovdataConfig

        Loads the configuration, creating it from the module defaults when it does not exist yet.

        .EXAMPLE
        Initialize-LovdataConfig -Force

        Discards the cached configuration and reads it from the vault again.

        .INPUTS
        None

        .OUTPUTS
        None

        .NOTES
        The cached configuration lives in the module scope, so it is shared by every command in the session.

        .LINK
        https://psmodule.io/Context/
    #>
    [OutputType([void])]
    [CmdletBinding()]
    param(
        # Reload the configuration from the vault instead of using the cached copy.
        [Parameter()]
        [switch] $Force
    )

    if (-not $Force -and $null -ne $script:Lovdata.Config) {
        Write-Debug 'The Lovdata configuration is already loaded.'
        return
    }

    $vault = $script:Lovdata.ContextVault
    $defaults = $script:Lovdata.DefaultConfig
    $stored = Get-Context -ID $defaults.ID -Vault $vault

    if ($null -eq $stored) {
        Write-Debug "Creating the Lovdata configuration context [$($defaults.ID)] in vault [$vault]."
        $created = Set-Context -ID $defaults.ID -Context $defaults -Vault $vault -PassThru
        $script:Lovdata.Config = [LovdataConfig]::new([pscustomobject]$created)
        return
    }

    $config = [LovdataConfig]::new([pscustomobject]$stored)
    $config.ID = $defaults.ID

    # Settings introduced after the context was stored come back as $null. Fall back to the module
    # defaults so the rest of the module never has to guard against a missing setting.
    $backfilled = $false
    foreach ($name in [LovdataConfig].GetProperties().Name) {
        if ($null -eq $config.$name) {
            $config.$name = $defaults.$name
            $backfilled = $true
        }
    }

    if ($backfilled) {
        Write-Debug 'Backfilling the stored Lovdata configuration with module defaults.'
        $null = Set-Context -ID $config.ID -Context $config -Vault $vault
    }

    $script:Lovdata.Config = $config
}
