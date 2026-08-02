function Set-LovdataConfig {
    <#
        .SYNOPSIS
        Change a module-wide Lovdata setting.

        .DESCRIPTION
        Updates one of the settings that apply to the module as a whole for the current session. Use it to
        point the module at a different API base URI, for example a test deployment. The change lives in
        memory only and is not persisted, so a new session starts from the module defaults again.

        .EXAMPLE
        Set-LovdataConfig -Name ApiBaseUri -Value $baseUri

        Points the module at the API base URI held in $baseUri.

        .EXAMPLE
        Set-LovdataConfig -Name ApiBaseUri -Value $baseUri -PassThru

        Points the module at the API base URI held in $baseUri and returns the updated settings.

        .INPUTS
        None

        .OUTPUTS
        LovdataConfig

        .NOTES
        The change is session-scoped and never written to disk, because this module stores no secret.

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
        [ValidateSet('ApiBaseUri')]
        [string] $Name,

        # The new value of the setting.
        [Parameter(Mandatory, Position = 1)]
        [AllowEmptyString()]
        [string] $Value,

        # Return the updated settings.
        [Parameter()]
        [switch] $PassThru
    )

    $config = Get-LovdataConfig

    if ($Name -eq 'ApiBaseUri' -and [string]::IsNullOrWhiteSpace($Value)) {
        throw 'ApiBaseUri cannot be empty. Provide the base URI of the Lovdata API, for example https://api.lovdata.no.'
    }

    if ($PSCmdlet.ShouldProcess("Lovdata setting [$Name]", "Set to [$Value]")) {
        $config.$Name = $Value

        if ($PassThru) {
            $config
        }
    }
}
