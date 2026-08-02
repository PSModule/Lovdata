function Resolve-LovdataContext {
    <#
        .SYNOPSIS
        Turn a context reference into a usable Lovdata context.

        .DESCRIPTION
        Accepts what a public command received on its Context parameter, which can be a context object,
        a context name, or nothing at all, and returns the stored context it refers to. Nothing means the
        default context. The result is checked for the API key and base URI the transport needs, so every
        caller fails with the same actionable message instead of a raw HTTP error later on.

        .EXAMPLE
        Resolve-LovdataContext -Context $null

        Returns the default context stored in the Lovdata vault.

        .EXAMPLE
        Resolve-LovdataContext -Context 'production'

        Returns the context stored under the name 'production'.

        .INPUTS
        None

        .OUTPUTS
        LovdataContext

        .NOTES
        This helper never picks a context on its own beyond falling back to the configured default.

        .LINK
        https://psmodule.io/Lovdata/Functions/Auth/Get-LovdataContext/
    #>
    [OutputType([LovdataContext])]
    [CmdletBinding()]
    param(
        # The context reference passed to the calling command. A LovdataContext, a context name, or $null.
        [Parameter(Mandatory)]
        [AllowNull()]
        [object] $Context
    )

    $resolved = if ($Context -is [LovdataContext]) {
        $Context
    } elseif ($Context -is [string]) {
        if ([string]::IsNullOrWhiteSpace($Context)) {
            Get-LovdataContext
        } else {
            Get-LovdataContext -Context $Context
        }
    } elseif ($null -ne $Context) {
        [LovdataContext]::new([pscustomobject]$Context)
    } else {
        Get-LovdataContext
    }

    if ($null -eq $resolved) {
        throw "No Lovdata context was found. Run 'Connect-LovdataAccount' to store an API key."
    }

    if ($null -eq $resolved.ApiKey -or $resolved.ApiKey.Length -eq 0) {
        throw "The Lovdata context [$($resolved.ID)] has no API key. Run 'Connect-LovdataAccount' to store one."
    }

    if ([string]::IsNullOrWhiteSpace($resolved.ApiBaseUri)) {
        throw "The Lovdata context [$($resolved.ID)] has no API base URI. Reconnect it with 'Connect-LovdataAccount'."
    }

    $resolved
}
