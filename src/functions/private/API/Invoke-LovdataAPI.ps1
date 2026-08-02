function Invoke-LovdataAPI {
    <#
        .SYNOPSIS
        Send an authenticated request to the Lovdata API.

        .DESCRIPTION
        Owns every HTTP call the module makes. Builds the request URI from the context's base URI and the
        endpoint, injects the API key as the 'X-API-Key' header Lovdata expects, and returns the response
        body deserialized from JSON when the API sends JSON. Failures are translated into terminating
        errors that carry the API's own problem description, with dedicated guidance for a rejected key
        and for an exhausted rate limit.

        .EXAMPLE
        Invoke-LovdataAPI -Endpoint '/v1/legalSource/list' -Context $context

        Sends an authenticated GET request and returns the deserialized response.

        .EXAMPLE
        Invoke-LovdataAPI -Endpoint '/v1/search' -Query @{ q = 'arbeidsmiljo' } -Context $context

        Sends an authenticated GET request with a URL-encoded query string.

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
        # The API endpoint to call, relative to the context's base URI, for example '/v1/legalSource/list'.
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
        [object] $Body,

        # The resolved context holding the API key and base URI to use.
        [Parameter(Mandatory)]
        [ValidateNotNull()]
        [LovdataContext] $Context
    )

    $uri = '{0}/{1}' -f $Context.ApiBaseUri.TrimEnd('/'), $Endpoint.TrimStart('/')

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
        Headers            = @{
            'X-API-Key' = ConvertFrom-SecureString -SecureString $Context.ApiKey -AsPlainText
            'Accept'    = 'application/json'
        }
        SkipHttpErrorCheck = $true
        ErrorAction        = 'Stop'
    }

    if ($null -ne $Body) {
        $params['ContentType'] = 'application/json'
        $params['Body'] = $Body | ConvertTo-Json -Depth 100
    }

    Write-Verbose "Sending [$Method] request to [$uri] using context [$($Context.ID)]."
    $response = Invoke-WebRequest @params

    $statusCode = [int]$response.StatusCode
    $remaining = Get-LovdataResponseHeader -Headers $response.Headers -Name 'X-RateLimit-Remaining'
    if ($remaining) {
        Write-Verbose "Lovdata rate limit remaining for this key: [$remaining]."
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
            401 {
                "The Lovdata API rejected the API key in context [$($Context.ID)] (401 Unauthorized). " +
                "Confirm the key is current and that the Lovdata user holds the 'api' role, then reconnect with 'Connect-LovdataAccount'."
            }
            429 {
                $reset = Get-LovdataResponseHeader -Headers $response.Headers -Name 'X-RateLimit-Reset'
                $resetText = if ($null -ne ($reset -as [long])) {
                    " The limit resets at $([datetimeoffset]::FromUnixTimeSeconds([long]$reset).ToLocalTime())."
                } else {
                    ''
                }
                "The Lovdata API rate limit for context [$($Context.ID)] is exhausted (429 Too Many Requests).$resetText"
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
