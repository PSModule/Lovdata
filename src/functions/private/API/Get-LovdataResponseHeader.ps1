function Get-LovdataResponseHeader {
    <#
        .SYNOPSIS
        Read a single response header value.

        .DESCRIPTION
        Returns the first value of a response header, or an empty string when the header is absent.
        Response headers arrive as a collection of values per name and the collection type differs
        between hosts, so every reader would otherwise repeat the same guards.

        .EXAMPLE
        Get-LovdataResponseHeader -Headers $response.Headers -Name 'X-RateLimit-Remaining'

        Returns the remaining rate-limit budget, or an empty string when the API did not report one.

        .INPUTS
        None

        .OUTPUTS
        System.String

        .NOTES
        Header names are matched case-insensitively, the way HTTP defines them.

        .LINK
        https://api.lovdata.no/swagger/index.html
    #>
    [OutputType([string])]
    [CmdletBinding()]
    param(
        # The response headers to read from.
        [Parameter(Mandatory)]
        [AllowNull()]
        [object] $Headers,

        # The name of the header to read.
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string] $Name
    )

    $value = $null
    if ($null -ne $Headers) {
        foreach ($key in @($Headers.Keys)) {
            if ([string]$key -eq $Name) {
                $value = @($Headers[$key])[0]
                break
            }
        }
    }

    [string]$value
}
