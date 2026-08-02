#Requires -Modules @{ ModuleName = 'Context'; ModuleVersion = '8.1.6' }

function Disconnect-LovdataAccount {
    <#
        .SYNOPSIS
        Remove a stored Lovdata API key.

        .DESCRIPTION
        Deletes a stored connection so the API key it holds is no longer on disk. Without arguments it
        removes the context commands use by default. When the removed context was the default, the
        default is cleared, so a later command asks for a new connection rather than silently using
        another account.

        .EXAMPLE
        Disconnect-LovdataAccount

        Removes the context commands use by default.

        .EXAMPLE
        Disconnect-LovdataAccount -Context 'production'

        Removes the context stored under the name 'production'.

        .EXAMPLE
        Get-LovdataContext -ListAvailable | Disconnect-LovdataAccount

        Removes every stored Lovdata connection.

        .INPUTS
        LovdataContext

        .INPUTS
        System.String

        .OUTPUTS
        None

        .NOTES
        Removing a context does not revoke the key with Lovdata. Revoke a leaked key with Lovdata as well.

        .LINK
        https://psmodule.io/Lovdata/Functions/Auth/Disconnect-LovdataAccount/

        .LINK
        https://psmodule.io/Lovdata/Functions/Auth/Connect-LovdataAccount/
    #>
    [OutputType([void])]
    [CmdletBinding(SupportsShouldProcess)]
    param(
        # The context to remove, as a name or a context object. Defaults to the context commands use.
        [Parameter(Position = 0, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [Alias('ID', 'Name')]
        [object] $Context
    )

    begin {
        Initialize-LovdataConfig
    }

    process {
        $name = if ($Context -is [LovdataContext]) {
            $Context.ID
        } elseif ($Context -is [string] -and -not [string]::IsNullOrWhiteSpace($Context)) {
            $Context
        } else {
            $script:Lovdata.Config.DefaultContext
        }

        if ([string]::IsNullOrWhiteSpace($name)) {
            throw "No default Lovdata context is configured. Name the context to remove with -Context."
        }

        if ($name -eq $script:Lovdata.Config.ID) {
            throw "The context name [$($script:Lovdata.Config.ID)] is reserved for the Lovdata module settings and cannot be removed."
        }

        if ($PSCmdlet.ShouldProcess("Lovdata context [$name]", 'Remove the stored API key')) {
            Remove-Context -ID $name -Vault $script:Lovdata.ContextVault

            if ($script:Lovdata.Config.DefaultContext -eq $name) {
                Write-Verbose "Clearing [$name] as the default Lovdata context."
                Set-LovdataConfig -Name DefaultContext -Value '' -Confirm:$false
            }
        }
    }
}
