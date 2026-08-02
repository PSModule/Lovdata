function Invoke-LovdataDownload {
    <#
        .SYNOPSIS
        Stream a Lovdata download endpoint to a file on disk.

        .DESCRIPTION
        Owns the binary download path the module uses, kept separate from the JSON transport in
        Invoke-LovdataAPI because it streams the response straight to disk rather than buffering it in
        memory. The Lovdata public data packages are tens of megabytes, so the body is written with
        Invoke-WebRequest -OutFile and the transfer is reported on the progress stream. The endpoint is
        open, so no authentication header is sent.

        .EXAMPLE
        Invoke-LovdataDownload -Endpoint '/v1/publicData/get/gjeldende-lover.tar.bz2' -OutFile 'C:\data\gjeldende-lover.tar.bz2'

        Streams the package to the given file.

        .INPUTS
        None

        .OUTPUTS
        None

        .NOTES
        Invoke-WebRequest raises a terminating error on an HTTP failure, which the caller is expected to surface.

        .LINK
        https://api.lovdata.no/swagger/index.html
    #>
    [OutputType([void])]
    [CmdletBinding()]
    param(
        # The download endpoint to call, relative to the configured base URI.
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string] $Endpoint,

        # The full path of the file to stream the response into.
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string] $OutFile
    )

    $baseUri = (Get-LovdataConfig).ApiBaseUri
    $uri = '{0}/{1}' -f $baseUri.TrimEnd('/'), $Endpoint.TrimStart('/')

    $activity = "Downloading [$([System.IO.Path]::GetFileName($OutFile))] from Lovdata"
    Write-Progress -Activity $activity -Status 'Transferring'
    try {
        Write-Verbose "Streaming [$uri] to [$OutFile]."
        Invoke-WebRequest -Uri $uri -OutFile $OutFile -ErrorAction Stop
    } finally {
        Write-Progress -Activity $activity -Completed
    }
}
