function Find-LovdataDocument {
    <#
        .SYNOPSIS
        Search the bundled Lovdata index.

        .DESCRIPTION
        Searches the metadata-only index the module ships and returns the matching documents, with no
        network access. A search term is matched against the title, short title, and the identifiers
        (RefID, legacy ID, and bare law ID); a plain term without wildcards is treated as a substring. The
        results can be narrowed further by ministry or legal area. All given filters must match.

        .EXAMPLE
        Find-LovdataDocument -Name 'folketrygd'

        Returns the documents whose title or identifier contains 'folketrygd'.

        .EXAMPLE
        Find-LovdataDocument -Ministry 'Justis*' -LegalArea 'Strafferett'

        Returns the documents from a matching ministry filed under a matching legal area.

        .INPUTS
        System.String

        .OUTPUTS
        LovdataDocument

        .NOTES
        The search runs against the bundled index, so it works offline.

        .LINK
        https://psmodule.io/Lovdata/Functions/Documents/Find-LovdataDocument/

        .LINK
        https://psmodule.io/Lovdata/Functions/Documents/Get-LovdataDocument/
    #>
    [OutputType([LovdataDocument])]
    [CmdletBinding()]
    param(
        # A term to match against the title, short title, or identifiers. A plain term matches as a substring.
        [Parameter(Position = 0, ValueFromPipeline)]
        [ValidateNotNullOrEmpty()]
        [string] $Name = '*',

        # A ministry to match. A plain term matches as a substring.
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string] $Ministry,

        # A legal area to match against its ID, name, or path. A plain term matches as a substring.
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string] $LegalArea
    )

    begin {
        $asPattern = {
            param($value)
            if ($value -match '[\*\?\[]') { $value } else { "*$value*" }
        }
    }

    process {
        $namePattern = & $asPattern $Name
        $ministryPattern = if ($PSBoundParameters.ContainsKey('Ministry')) { & $asPattern $Ministry }
        $areaPattern = if ($PSBoundParameters.ContainsKey('LegalArea')) { & $asPattern $LegalArea }

        Import-LovdataIndexData | Where-Object {
            $document = $_
            $nameFields = @($document.Title, $document.TitleShort, $document.RefID, $document.LegacyID, $document.LawID)
            $nameMatch = [bool](@($nameFields) -like $namePattern)
            $ministryMatch = -not $ministryPattern -or [bool](@($document.Ministry) -like $ministryPattern)
            $areaValues = foreach ($area in $document.LegalAreas) { $area.ID; $area.Name; $area.Path }
            $areaMatch = -not $areaPattern -or [bool](@($areaValues) -like $areaPattern)
            $nameMatch -and $ministryMatch -and $areaMatch
        }
    }
}
