#Requires -Modules @{ ModuleName = 'Context'; ModuleVersion = '8.1.6' }

function Set-LovdataConfig {
    <#
        .SYNOPSIS
        Change a module-wide Lovdata setting.

        .DESCRIPTION
        Updates one of the settings that apply to the module as a whole and stores it so it survives the
        session. Use it to point the module at a different API base URI, or to choose which stored
        context commands fall back to when none is given.

        .EXAMPLE
        Set-LovdataConfig -Name ApiBaseUri -Value 'https://api.lovdata.no'

        Points new connections at the given API base URI.

        .EXAMPLE
        Set-LovdataConfig -Name DefaultContext -Value 'production' -PassThru

        Makes 'production' the context commands use by default and returns the updated settings.

        .INPUTS
        None

        .OUTPUTS
        LovdataConfig

        .NOTES
        Changing ApiBaseUri does not move contexts that are already stored; those keep the base URI they
        were connected with.

        .LINK
        https://psmodule.io/Lovdata/Functions/Config/Set-LovdataConfig/

        .LINK
        https://psmodule.io/Lovdata/Functions/Config/Get-LovdataConfig/
    #>
    [OutputType([LovdataConfig])]
    [CmdletBinding(SupportsShouldProcess)]
    param(
        # The setting to change.
        [Parameter(Mandatory, Position = 0)]
        [ValidateSet('ApiBaseUri', 'DefaultContext')]
        [string] $Name,

        # The new value of the setting. DefaultContext accepts an empty string to clear the default.
        [Parameter(Mandatory, Position = 1)]
        [AllowEmptyString()]
        [string] $Value,

        # Return the updated settings.
        [Parameter()]
        [switch] $PassThru
    )

    Initialize-LovdataConfig

    if ($Name -eq 'ApiBaseUri' -and [string]::IsNullOrWhiteSpace($Value)) {
        throw 'ApiBaseUri cannot be empty. Provide the base URI of the Lovdata API, for example https://api.lovdata.no.'
    }

    if ($PSCmdlet.ShouldProcess("Lovdata setting [$Name]", "Set to [$Value]")) {
        $script:Lovdata.Config.$Name = $Value
        $null = Set-Context -ID $script:Lovdata.Config.ID -Context $script:Lovdata.Config -Vault $script:Lovdata.ContextVault

        if ($PassThru) {
            $script:Lovdata.Config
        }
    }
}
