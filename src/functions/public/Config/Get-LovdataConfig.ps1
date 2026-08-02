function Get-LovdataConfig {
    <#
        .SYNOPSIS
        Get the module-wide Lovdata settings.

        .DESCRIPTION
        Returns the settings that apply to the module as a whole rather than to a single stored API key:
        the API base URI new connections use, and the name of the context commands fall back to when
        none is given. The settings are created from the module defaults the first time they are read.

        .EXAMPLE
        Get-LovdataConfig

        Returns the module-wide settings.

        .EXAMPLE
        (Get-LovdataConfig).DefaultContext

        Returns the name of the context used by commands that are not given one.

        .INPUTS
        None

        .OUTPUTS
        LovdataConfig

        .NOTES
        Settings are stored in their own context and are never mixed with stored API keys.

        .LINK
        https://psmodule.io/Lovdata/Functions/Config/Get-LovdataConfig/

        .LINK
        https://psmodule.io/Context/
    #>
    [OutputType([LovdataConfig])]
    [CmdletBinding()]
    param()

    Initialize-LovdataConfig
    $script:Lovdata.Config
}
