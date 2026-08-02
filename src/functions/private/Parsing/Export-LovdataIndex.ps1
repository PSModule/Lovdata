function Export-LovdataIndex {
    <#
        .SYNOPSIS
        Write the bundled metadata index for a set of Lovdata documents.

        .DESCRIPTION
        Serialises the metadata of the given documents into one JSON file per source under the output
        directory, for example 'LovdataIndex.nl.json'. Only metadata is written, never the document body,
        which keeps the index small and safe to ship. The output is deterministic: keys are written in a
        fixed order and documents are sorted by RefID, so an unchanged corpus produces a byte-identical
        file and therefore no diff. Files are written with Unix line endings to match the repository's
        gitattributes.

        .EXAMPLE
        $documents | Export-LovdataIndex -Path ./src

        Writes one index file per source into the src directory.

        .INPUTS
        LovdataDocument

        .OUTPUTS
        System.IO.FileInfo

        .NOTES
        Dates are written as yyyy-MM-dd strings so the file stays stable and culture-independent.

        .LINK
        https://api.lovdata.no/om-api-tjenesten/
    #>
    [OutputType([System.IO.FileInfo])]
    [CmdletBinding()]
    param(
        # The documents to index.
        [Parameter(Mandatory, ValueFromPipeline)]
        [ValidateNotNull()]
        [LovdataDocument] $Document,

        # The directory to write the index files into.
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string] $Path
    )

    begin {
        $documents = [System.Collections.Generic.List[object]]::new()

        $dateToText = {
            param($value)
            if ($null -eq $value) { $null } else { ([datetime]$value).ToString('yyyy-MM-dd', [cultureinfo]::InvariantCulture) }
        }

        $dateInfo = {
            param($info)
            if ($null -eq $info) {
                return $null
            }
            [ordered]@{
                Raw   = $info.Raw
                Dates = @(foreach ($d in $info.Dates) { & $dateToText $d })
                Note  = $info.Note
            }
        }

        $reference = {
            param($ref)
            [ordered]@{
                RefID = $ref.RefID
                Text  = $ref.Text
                Date  = & $dateToText $ref.Date
            }
        }

        $area = {
            param($a)
            [ordered]@{
                ID       = $a.ID
                Name     = $a.Name
                Segments = @(foreach ($s in $a.Segments) { [ordered]@{ ID = $s.ID; Name = $s.Name } })
                Path     = $a.Path
            }
        }
    }

    process {
        $documents.Add($Document)
    }

    end {
        foreach ($group in $documents | Group-Object -Property Source) {
            $records = foreach ($doc in ($group.Group | Sort-Object -Property RefID -Culture '')) {
                [ordered]@{
                    Title              = $doc.Title
                    TitleShort         = $doc.TitleShort
                    LegacyID           = $doc.LegacyID
                    LawID              = $doc.LawID
                    RefID              = $doc.RefID
                    DokID              = $doc.DokID
                    Ministry           = @($doc.Ministry)
                    LegalAreas         = @(foreach ($a in $doc.LegalAreas) { & $area $a })
                    DateInForce        = & $dateInfo $doc.DateInForce
                    LastUpdated        = & $dateInfo $doc.LastUpdated
                    LastChangedBy      = @(foreach ($r in $doc.LastChangedBy) { & $reference $r })
                    LastChangeInForce  = & $dateInfo $doc.LastChangeInForce
                    MiscInformation    = $doc.MiscInformation
                    DateOfPublication  = & $dateInfo $doc.DateOfPublication
                    ChangesToDocuments = @(foreach ($r in $doc.ChangesToDocuments) { & $reference $r })
                    EeaReferences      = $doc.EeaReferences
                    AppliesTo          = $doc.AppliesTo
                    Source             = $doc.Source
                    SourceFile         = $doc.SourceFile
                }
            }

            $payload = [ordered]@{
                schemaVersion = 1
                source        = $group.Name
                documentCount = @($records).Count
                documents     = @($records)
            }

            $json = ($payload | ConvertTo-Json -Depth 20) -replace "`r`n", "`n"
            if (-not $json.EndsWith("`n")) {
                $json += "`n"
            }

            $file = Join-Path -Path $Path -ChildPath ('LovdataIndex.{0}.json' -f $group.Name)
            [System.IO.File]::WriteAllText($file, $json, [System.Text.UTF8Encoding]::new($false))
            Get-Item -LiteralPath $file
        }
    }
}
