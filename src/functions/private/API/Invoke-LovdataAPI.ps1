function Invoke-LovdataAPI {
    <#
        .SYNOPSIS
        Send a request to the Lovdata API.

        .DESCRIPTION
        Owns every JSON HTTP call the module makes. Builds the request URI from the module's configured
        base URI and the endpoint, and returns the response body deserialized from JSON when the API
        sends JSON, or the raw text otherwise. Failures are translated into terminating errors that carry
        the API's own problem description, with dedicated guidance for an exhausted rate limit.

        The open Lovdata endpoints this release covers need no credential, so no authentication header is
        sent. The service still rate limits unauthenticated callers, so the remaining budget it reports is
        written to the verbose stream.

        .EXAMPLE
        Invoke-LovdataAPI -Endpoint '/v1/publicData/list'

        Sends a GET request and returns the deserialized response.

        .EXAMPLE
        Invoke-LovdataAPI -Endpoint '/version'

        Sends a GET request to an endpoint that answers with plain text and returns it unchanged.

        .INPUTS
        None

        .OUTPUTS
        System.Object

        .NOTES
        The remaining rate-limit budget reported by Lovdata is written to the verbose stream so long
        running scripts can pace themselves.

        .LINK
        https://api.lovdata.no/swagger/index.html
    #>
    [OutputType([object])]
    [CmdletBinding()]
    param(
        # The API endpoint to call, relative to the configured base URI, for example '/v1/publicData/list'.
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string] $Endpoint,

        # The HTTP method to use.
        [Parameter()]
        [ValidateSet('Get', 'Post', 'Put', 'Delete')]
        [string] $Method = 'Get',

        # The query string parameters to send. Entries with a null value are left out.
        [Parameter()]
        [ValidateNotNull()]
        [hashtable] $Query = @{},

        # The request payload, serialized as JSON.
        [Parameter()]
        [AllowNull()]
        [object] $Body
    )

    $baseUri = (Get-LovdataConfig).ApiBaseUri
    $uri = '{0}/{1}' -f $baseUri.TrimEnd('/'), $Endpoint.TrimStart('/')

    $queryString = @(
        $Query.GetEnumerator() |
            Where-Object { $null -ne $_.Value } |
            Sort-Object -Property Key |
            ForEach-Object {
                '{0}={1}' -f [uri]::EscapeDataString([string]$_.Key), [uri]::EscapeDataString([string]$_.Value)
            }
    ) -join '&'
    if ($queryString) {
        $uri = '{0}?{1}' -f $uri, $queryString
    }

    $params = @{
        Method             = $Method
        Uri                = $uri
        Headers            = @{ 'Accept' = 'application/json' }
        SkipHttpErrorCheck = $true
        ErrorAction        = 'Stop'
    }

    if ($null -ne $Body) {
        $params['ContentType'] = 'application/json'
        $params['Body'] = $Body | ConvertTo-Json -Depth 100
    }

    Write-Verbose "Sending [$Method] request to [$uri]."
    $response = Invoke-WebRequest @params

    $statusCode = [int]$response.StatusCode
    $remaining = Get-LovdataResponseHeader -Headers $response.Headers -Name 'X-RateLimit-Remaining'
    if ($remaining) {
        Write-Verbose "Lovdata rate limit remaining: [$remaining]."
    }

    $content = [string]$response.Content
    $payload = if ([string]::IsNullOrWhiteSpace($content)) {
        $null
    } else {
        try {
            $content | ConvertFrom-Json -ErrorAction Stop
        } catch {
            # Not every endpoint answers with JSON; '/ping' replies with plain text.
            $content
        }
    }

    if ($statusCode -lt 400) {
        $payload
    } else {
        # Lovdata reports failures as an RFC 9457 problem document; surface its own wording when present.
        $apiMessage = ''
        if ($payload -is [string]) {
            $apiMessage = $payload
        } elseif ($null -ne $payload) {
            foreach ($name in 'detail', 'message', 'title') {
                $property = $payload.PSObject.Properties[$name]
                if ($null -ne $property -and -not [string]::IsNullOrWhiteSpace([string]$property.Value)) {
                    $apiMessage = [string]$property.Value
                    break
                }
            }
        }

        $message = switch ($statusCode) {
            429 {
                $reset = Get-LovdataResponseHeader -Headers $response.Headers -Name 'X-RateLimit-Reset'
                $resetText = if ($null -ne ($reset -as [long])) {
                    " The limit resets at $([datetimeoffset]::FromUnixTimeSeconds([long]$reset).ToLocalTime())."
                } else {
                    ''
                }
                "The Lovdata API rate limit is exhausted (429 Too Many Requests).$resetText"
            }
            default {
                "The Lovdata API request to [$uri] failed with status [$statusCode]."
            }
        }

        if ($apiMessage) {
            $message = '{0} The API reported: {1}' -f $message, $apiMessage
        }

        throw $message
    }
}
