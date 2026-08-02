function Import-LovdataIndexData {
    <#
        .SYNOPSIS
        Load the bundled Lovdata metadata index.

        .DESCRIPTION
        Reads the per-source index files the module ships and returns their documents as LovdataDocument
        objects, with every metadata shape rebuilt from the JSON. The files are found by probing the
        module root, where the build copies the shipped data, and the source tree, so the loader works
        both in the built module and when running from source. The result is cached for the session so
        repeated lookups do not re-read the files.

        .EXAMPLE
        Import-LovdataIndexData

        Returns every document in the bundled index.

        .INPUTS
        None

        .OUTPUTS
        LovdataDocument

        .NOTES
        Pass Refresh to discard the cached data and read the files again.

        .LINK
        https://api.lovdata.no/om-api-tjenesten/
    #>
    [OutputType([LovdataDocument], [LovdataDocument[]])]
    [CmdletBinding()]
    param(
        # Discard the cached index and read the files from disk again.
        [Parameter()]
        [switch] $Refresh
    )

    if ($Refresh) {
        $script:LovdataIndexCache = $null
    }
    if ($null -ne $script:LovdataIndexCache) {
        return [LovdataDocument[]] $script:LovdataIndexCache
    }

    # Probe the module root first, then climb the source tree, so the files are found either way.
    $candidates = [System.Collections.Generic.List[string]]::new()
    $candidates.Add($PSScriptRoot)
    $directory = $PSScriptRoot
    for ($level = 0; $level -lt 6 -and $directory; $level++) {
        $candidates.Add($directory)
        $directory = Split-Path -Path $directory -Parent
    }

    $files = @()
    foreach ($candidate in $candidates) {
        if ([string]::IsNullOrEmpty($candidate)) {
            continue
        }
        $found = Get-ChildItem -Path $candidate -Filter 'LovdataIndex.*.json' -File -ErrorAction SilentlyContinue |
            Where-Object { $_.Name -ne 'LovdataIndex.manifest.json' }
        if ($found) {
            $files = $found
            break
        }
    }

    $documents = foreach ($file in $files) {
        $data = Get-Content -LiteralPath $file.FullName -Raw | ConvertFrom-Json
        foreach ($record in $data.documents) {
            [LovdataDocument]::new([pscustomobject]$record)
        }
    }

    $script:LovdataIndexCache = [LovdataDocument[]]@($documents)
    [LovdataDocument[]] $script:LovdataIndexCache
}
