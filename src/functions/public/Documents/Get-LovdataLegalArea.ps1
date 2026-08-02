function Get-LovdataLegalArea {
    <#
        .SYNOPSIS
        Get the Lovdata legal-area taxonomy.

        .DESCRIPTION
        Returns the legal areas documents are filed under, derived from the bundled index. Lovdata
        organises areas as a hierarchy, so every level is returned as its own area, from the top-level
        areas down to the leaves, each carrying its identifier, name, and full path. The list is distinct
        and sorted by identifier, and can be narrowed by identifier or name.

        .EXAMPLE
        Get-LovdataLegalArea

        Returns the whole legal-area taxonomy.

        .EXAMPLE
        Get-LovdataLegalArea -ID '09*'

        Returns the areas whose identifier starts with '09'.

        .INPUTS
        None

        .OUTPUTS
        LovdataLegalArea

        .NOTES
        The taxonomy is derived from the bundled index, so it works offline.

        .LINK
        https://psmodule.io/Lovdata/Functions/Documents/Get-LovdataLegalArea/

        .LINK
        https://psmodule.io/Lovdata/Functions/Documents/Find-LovdataDocument/
    #>
    [OutputType([LovdataLegalArea])]
    [CmdletBinding()]
    param(
        # An identifier to match, for example '09' or '09.03'. Supports wildcards.
        [Parameter()]
        [SupportsWildcards()]
        [ValidateNotNullOrEmpty()]
        [string] $ID = '*',

        # A name to match. Supports wildcards.
        [Parameter()]
        [SupportsWildcards()]
        [ValidateNotNullOrEmpty()]
        [string] $Name = '*'
    )

    $seen = @{}
    foreach ($document in Import-LovdataIndexData) {
        foreach ($area in $document.LegalAreas) {
            $segments = @($area.Segments)
            for ($index = 0; $index -lt $segments.Count; $index++) {
                $segment = $segments[$index]
                if ($seen.ContainsKey($segment.ID)) {
                    continue
                }
                $seen[$segment.ID] = [LovdataLegalArea]@{
                    ID       = $segment.ID
                    Name     = $segment.Name
                    Segments = @($segments[0..$index])
                    Path     = (@($segments[0..$index]).Name -join ' > ')
                }
            }
        }
    }

    $seen.Values |
        Where-Object { $_.ID -like $ID -and $_.Name -like $Name } |
        Sort-Object -Property ID -Culture ''
}
