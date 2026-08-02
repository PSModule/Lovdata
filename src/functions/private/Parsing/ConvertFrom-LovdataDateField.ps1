function ConvertFrom-LovdataDateField {
    <#
        .SYNOPSIS
        Parse a Lovdata date field into a LovdataDateInfo.

        .DESCRIPTION
        Lovdata date fields are rarely a clean single date. A field may carry several dates, a prose
        qualifier, or a parenthetical note. This helper keeps the raw text exactly as published, extracts
        every ISO date it can find, and exposes the leftover prose as a note, so nothing Lovdata published
        is lost.

        .EXAMPLE
        ConvertFrom-LovdataDateField -Text '1966-05-06 med virkning fra 1963-01-01'

        Returns a LovdataDateInfo carrying both dates and the qualifier as its note.

        .INPUTS
        System.String

        .OUTPUTS
        LovdataDateInfo

        .NOTES
        Dates are matched as ISO yyyy-MM-dd tokens and parsed with the invariant culture.

        .LINK
        https://api.lovdata.no/om-api-tjenesten/
    #>
    [OutputType([LovdataDateInfo])]
    [CmdletBinding()]
    param(
        # The raw text of a date field.
        [Parameter(Mandatory, ValueFromPipeline)]
        [AllowEmptyString()]
        [AllowNull()]
        [string] $Text
    )

    process {
        $raw = if ($null -eq $Text) { '' } else { $Text.Trim() }

        $dates = foreach ($match in [regex]::Matches($raw, '\d{4}-\d{2}-\d{2}')) {
            [datetime]::ParseExact(
                $match.Value,
                'yyyy-MM-dd',
                [cultureinfo]::InvariantCulture,
                [System.Globalization.DateTimeStyles]::None
            )
        }

        # Whatever is left once the dates and their surrounding parentheses are removed is the note.
        $note = ($raw -replace '\d{4}-\d{2}-\d{2}', '') -replace '[()]', ' '
        $note = ($note -replace '\s+', ' ').Trim().Trim(',', '.', ';').Trim()
        if ([string]::IsNullOrWhiteSpace($note)) {
            $note = $null
        }

        [LovdataDateInfo]@{
            Raw   = $raw
            Dates = [datetime[]]@($dates)
            Note  = $note
        }
    }
}
