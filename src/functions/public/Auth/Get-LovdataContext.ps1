#Requires -Modules @{ ModuleName = 'Context'; ModuleVersion = '8.1.6' }

function Get-LovdataContext {
    <#
        .SYNOPSIS
        Get a stored Lovdata context.

        .DESCRIPTION
        Returns the connections stored in the Lovdata vault. Without arguments it returns the context
        commands use by default; with a name it returns that one; with ListAvailable it returns every
        stored connection. The API key is part of the returned object but is held as a SecureString, so
        it is never displayed.

        .EXAMPLE
        Get-LovdataContext

        Returns the context commands use when none is given.

        .EXAMPLE
        Get-LovdataContext -Context 'production'

        Returns the context stored under the name 'production'.

        .EXAMPLE
        Get-LovdataContext -ListAvailable

        Returns every stored Lovdata connection.

        .INPUTS
        None

        .OUTPUTS
        LovdataContext

        .NOTES
        The module's own settings context is excluded, so only real connections are returned.

        .LINK
        https://psmodule.io/Lovdata/Functions/Auth/Get-LovdataContext/

        .LINK
        https://psmodule.io/Lovdata/Functions/Auth/Connect-LovdataAccount/
    #>
    [OutputType([LovdataContext])]
    [CmdletBinding(DefaultParameterSetName = 'As the default context')]
    param(
        # The name of the stored context to return.
        [Parameter(Mandatory, Position = 0, ParameterSetName = 'By context name')]
        [ValidateNotNullOrEmpty()]
        [Alias('Name')]
        [string] $Context,

        # Return every stored context instead of a single one.
        [Parameter(Mandatory, ParameterSetName = 'As a list of every context')]
        [switch] $ListAvailable
    )

    Initialize-LovdataConfig
    $configID = $script:Lovdata.Config.ID

    $id = switch ($PSCmdlet.ParameterSetName) {
        'By context name' {
            if ($Context -eq $configID) {
                throw "The context name [$configID] is reserved for the Lovdata module settings."
            }
            $Context
        }
        'As a list of every context' {
            '*'
        }
        default {
            if ([string]::IsNullOrWhiteSpace($script:Lovdata.Config.DefaultContext)) {
                throw "No default Lovdata context is configured. Run 'Connect-LovdataAccount' to store an API key."
            }
            $script:Lovdata.Config.DefaultContext
        }
    }

    $contexts = @(
        Get-Context -ID $id -Vault $script:Lovdata.ContextVault |
            Where-Object { $_.ID -ne $configID } |
            ForEach-Object { [LovdataContext]::new([pscustomobject]$_) }
    )

    if (-not $ListAvailable -and $contexts.Count -eq 0) {
        throw "The Lovdata context [$id] was not found. Run 'Connect-LovdataAccount' to store it."
    }

    $contexts | Sort-Object -Property ID
}
