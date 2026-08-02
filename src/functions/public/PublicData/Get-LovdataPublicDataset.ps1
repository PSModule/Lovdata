function Get-LovdataPublicDataset {
    <#
        .SYNOPSIS
        Get the free open data packages Lovdata publishes.

        .DESCRIPTION
        Returns the public data packages Lovdata publishes as free open data under the Norwegian Licence
        for Open Government Data (NLOD) 2.0, such as the current acts and central regulations. Each entry
        carries the filename Save-LovdataPublicDataset downloads, plus the size and last-modified date so
        a caller can decide what to fetch. No account and no API key are needed.

        Content retrieved through this command remains subject to Lovdata's terms; credit Lovdata as the
        source when redistributing it.

        .EXAMPLE
        Get-LovdataPublicDataset

        Returns every public data package Lovdata publishes.

        .EXAMPLE
        Get-LovdataPublicDataset -FileName 'gjeldende-*'

        Returns the packages whose filename starts with 'gjeldende-'.

        .INPUTS
        None

        .OUTPUTS
        LovdataPublicDataset

        .NOTES
        The packages are published under the Norwegian Licence for Open Government Data (NLOD) 2.0.

        .LINK
        https://psmodule.io/Lovdata/Functions/PublicData/Get-LovdataPublicDataset/

        .LINK
        https://psmodule.io/Lovdata/Functions/PublicData/Save-LovdataPublicDataset/
    #>
    [OutputType([LovdataPublicDataset])]
    [CmdletBinding()]
    param(
        # The filename of the packages to return. Supports wildcards.
        [Parameter(Position = 0)]
        [SupportsWildcards()]
        [ValidateNotNullOrEmpty()]
        [string] $FileName = '*'
    )

    $response = Invoke-LovdataAPI -Endpoint '/v1/publicData/list'

    $datasets = foreach ($item in @($response)) {
        if ($null -eq $item) {
            continue
        }

        # The JSON deserializer already turns an ISO-8601 'Z' timestamp into a UTC DateTime, so casting
        # it back to a string first would render it in the current culture and lose the offset.
        $lastModified = if ($item.lastModified -is [datetime]) {
            [datetime]$item.lastModified
        } else {
            [datetime]::Parse(
                [string]$item.lastModified,
                [cultureinfo]::InvariantCulture,
                [System.Globalization.DateTimeStyles]::RoundtripKind
            )
        }
        if ($lastModified.Kind -eq [System.DateTimeKind]::Unspecified) {
            # Lovdata reports these timestamps in UTC even when the value carries no offset.
            $lastModified = [datetime]::SpecifyKind($lastModified, [System.DateTimeKind]::Utc)
        }

        [LovdataPublicDataset]@{
            FileName     = [string]$item.filename
            Description  = [string]$item.description
            SizeBytes    = [long]$item.sizeBytes
            LastModified = $lastModified
        }
    }

    $datasets | Where-Object { $_.FileName -like $FileName } | Sort-Object -Property FileName
}
