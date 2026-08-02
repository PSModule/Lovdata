function Get-LovdataConfig {
    <#
        .SYNOPSIS
        Get the module-wide Lovdata settings.

        .DESCRIPTION
        Returns the settings that apply to the module as a whole for the current session, principally the
        API base URI every command sends requests to. The settings are held in memory only: they are
        seeded from the module defaults the first time they are read and are not persisted, so a new
        session starts from the defaults again.

        .EXAMPLE
        Get-LovdataConfig

        Returns the module-wide settings.

        .EXAMPLE
        (Get-LovdataConfig).ApiBaseUri

        Returns the API base URI the module sends requests to.

        .INPUTS
        None

        .OUTPUTS
        LovdataConfig

        .NOTES
        The settings are session-scoped and never written to disk, because this module stores no secret.

        .LINK
        https://psmodule.io/Lovdata/Functions/Config/Get-LovdataConfig/

        .LINK
        https://psmodule.io/Lovdata/Functions/Config/Set-LovdataConfig/
    #>
    [OutputType([LovdataConfig])]
    [CmdletBinding()]
    param()

    if ($null -eq $script:Lovdata.Config) {
        $script:Lovdata.Config = [LovdataConfig]@{
            ApiBaseUri = $script:Lovdata.DefaultConfig.ApiBaseUri
        }
    }

    $script:Lovdata.Config
}
