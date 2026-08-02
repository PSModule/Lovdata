function Get-LovdataApiVersion {
    <#
        .SYNOPSIS
        Get the version of the deployed Lovdata API service.

        .DESCRIPTION
        Returns the deployment name, build timestamp, and source revision the Lovdata API reports. The
        endpoint is open, so no account and no API key are needed. Use it to record which build a script
        ran against, or as a first-run diagnostic alongside Test-LovdataConnection.

        .EXAMPLE
        Get-LovdataApiVersion

        Returns the deployed API version.

        .EXAMPLE
        (Get-LovdataApiVersion).Revision

        Returns the source revision the deployed API was built from.

        .INPUTS
        None

        .OUTPUTS
        LovdataApiVersion

        .NOTES
        The build timestamp is returned as Lovdata reports it, for example '2026-07-31-1613'.

        .LINK
        https://psmodule.io/Lovdata/Functions/Service/Get-LovdataApiVersion/

        .LINK
        https://psmodule.io/Lovdata/Functions/Service/Test-LovdataConnection/
    #>
    [OutputType([LovdataApiVersion])]
    [CmdletBinding()]
    param()

    $response = Invoke-LovdataAPI -Endpoint '/version'

    [LovdataApiVersion]@{
        Name      = [string]$response.name
        Timestamp = [string]$response.timestamp
        Revision  = [string]$response.revision
    }
}
