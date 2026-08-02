function Test-LovdataConnection {
    <#
        .SYNOPSIS
        Test whether the Lovdata API is reachable.

        .DESCRIPTION
        Sends a request to the Lovdata service ping endpoint and returns whether it answered. The endpoint
        is open, so no account and no API key are needed. The command never throws when the service is
        unreachable; it writes a warning and returns false, so it is safe to use directly in a
        conditional as a first-run diagnostic.

        .EXAMPLE
        Test-LovdataConnection

        Returns $true when the Lovdata API answered, or $false when it did not.

        .EXAMPLE
        if (Test-LovdataConnection) { Get-LovdataPublicDataset }

        Only lists the public data packages when the service is reachable.

        .INPUTS
        None

        .OUTPUTS
        System.Boolean

        .NOTES
        A failure to reach the service is reported as $false with a warning rather than a terminating error.

        .LINK
        https://psmodule.io/Lovdata/Functions/Service/Test-LovdataConnection/

        .LINK
        https://psmodule.io/Lovdata/Functions/Service/Get-LovdataApiVersion/
    #>
    [OutputType([bool])]
    [CmdletBinding()]
    param()

    try {
        $null = Invoke-LovdataAPI -Endpoint '/ping'
        $true
    } catch {
        $reason = $_.Exception.Message
        Write-Warning "The Lovdata API could not be reached: $reason"
        $false
    }
}
