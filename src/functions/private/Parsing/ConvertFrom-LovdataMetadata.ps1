function ConvertFrom-LovdataMetadata {
    <#
        .SYNOPSIS
        Parse a Lovdata document's metadata into a LovdataDocument.

        .DESCRIPTION
        Reads the document key-info block that every Lovdata archive document carries and returns a
        LovdataDocument with its metadata filled in. Fields are keyed on the stable class attribute of each
        entry, never the visible label, because the label varies by target language while the class does
        not. Date-bearing fields keep their raw text alongside any parsed dates, list fields become
        collections, and the legal areas keep their hierarchical paths, so no field is reduced in a way
        that would lose information. The body collections are left empty for a caller to fill.

        .EXAMPLE
        ConvertFrom-LovdataMetadata -Document $xml

        Returns a LovdataDocument carrying the metadata read from the given XML document.

        .INPUTS
        System.Xml.XmlDocument

        .OUTPUTS
        LovdataDocument

        .NOTES
        Miscellaneous and EEA fields are kept as text; the primary reference fields are the change history
        and the list of changed documents.

        .LINK
        https://api.lovdata.no/om-api-tjenesten/
    #>
    [OutputType([LovdataDocument])]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute(
        'PSUseSingularNouns', '',
        Justification = 'Metadata is a mass noun and reads correctly as a single noun here.'
    )]
    [CmdletBinding()]
    param(
        # The XML document of a Lovdata archive document.
        [Parameter(Mandatory, ValueFromPipeline)]
        [ValidateNotNull()]
        [System.Xml.XmlDocument] $Document
    )

    process {
        $result = [LovdataDocument]::new()

        $dl = $Document.SelectSingleNode("//*[local-name()='dl'][@class='data-document-key-info']")
        if ($null -eq $dl) {
            return $result
        }

        # Index the entries by their class attribute, which is stable across target languages.
        $meta = @{}
        foreach ($dd in $dl.SelectNodes("*[local-name()='dd']")) {
            $class = $dd.GetAttribute('class')
            if (-not $meta.ContainsKey($class)) {
                $meta[$class] = $dd
            }
        }

        $text = {
            param($class)
            if ($meta.ContainsKey($class)) {
                $meta[$class].InnerText.Trim()
            }
        }

        $listItems = {
            param($class)
            if (-not $meta.ContainsKey($class)) {
                return @()
            }
            $values = foreach ($li in $meta[$class].SelectNodes(".//*[local-name()='li']")) {
                $li.InnerText.Trim()
            }
            @($values)
        }

        $references = {
            param($class)
            if (-not $meta.ContainsKey($class)) {
                return @()
            }
            $node = $meta[$class]
            $date = (ConvertFrom-LovdataDateField -Text $node.InnerText).Dates | Select-Object -First 1
            $refs = foreach ($a in $node.SelectNodes(".//*[local-name()='a']")) {
                [LovdataDocumentReference]@{
                    RefID = $a.GetAttribute('href')
                    Text  = $a.InnerText.Trim()
                    Date  = $date
                }
            }
            @($refs)
        }

        $parseToc = {
            param($ul)
            $entries = foreach ($li in $ul.SelectNodes("*[local-name()='li']")) {
                $anchor = $li.SelectSingleNode("*[local-name()='a']")
                $entry = [LovdataTocEntry]@{
                    Title  = if ($anchor) { $anchor.InnerText.Trim() } else { $li.InnerText.Trim() }
                    Anchor = if ($anchor) { $anchor.GetAttribute('href') } else { '' }
                }
                $childUl = $li.SelectSingleNode("*[local-name()='ul']")
                if ($childUl) {
                    $entry.Children = @(& $parseToc $childUl)
                }
                $entry
            }
            @($entries)
        }

        $result.Title = & $text 'title'
        $result.TitleShort = & $text 'titleShort'
        $result.LegacyID = & $text 'legacyID'
        $result.LawID = if ($result.LegacyID) { $result.LegacyID -replace '^[A-Za-z]+-', '' }
        $result.RefID = & $text 'refid'
        $result.DokID = & $text 'dokid'
        $result.MiscInformation = & $text 'miscInformation'
        $result.EeaReferences = & $text 'eeaReferences'
        $result.AppliesTo = & $text 'appliesTo'

        $result.Ministry = & $listItems 'ministry'

        $areas = foreach ($li in $dl.SelectNodes("*[local-name()='dd'][@class='legalArea']//*[local-name()='li']")) {
            $segments = foreach ($a in $li.SelectNodes(".//*[local-name()='a']")) {
                [pscustomobject]@{
                    ID   = $a.GetAttribute('href') -replace '^legal-areas/', ''
                    Name = $a.InnerText.Trim()
                }
            }
            $segments = @($segments)
            if ($segments.Count -eq 0) {
                continue
            }
            [LovdataLegalArea]@{
                ID       = $segments[-1].ID
                Name     = $segments[-1].Name
                Segments = $segments
                Path     = ($segments.Name -join ' > ')
            }
        }
        $result.LegalAreas = @($areas)

        if ($meta.ContainsKey('dateInForce')) {
            $result.DateInForce = ConvertFrom-LovdataDateField -Text $meta['dateInForce'].InnerText
        }
        if ($meta.ContainsKey('lastupdated')) {
            $result.LastUpdated = ConvertFrom-LovdataDateField -Text $meta['lastupdated'].InnerText
        }
        if ($meta.ContainsKey('lastChangeInForce')) {
            $result.LastChangeInForce = ConvertFrom-LovdataDateField -Text $meta['lastChangeInForce'].InnerText
        }
        if ($meta.ContainsKey('dateOfPublication')) {
            $result.DateOfPublication = ConvertFrom-LovdataDateField -Text $meta['dateOfPublication'].InnerText
        }

        $result.LastChangedBy = & $references 'lastChangedBy'
        $result.ChangesToDocuments = & $references 'changesToDocuments'

        if ($meta.ContainsKey('table-of-contents')) {
            $topUl = $meta['table-of-contents'].SelectSingleNode("*[local-name()='ul']")
            if ($topUl) {
                $result.TableOfContents = @(& $parseToc $topUl)
            }
        }

        $result
    }
}
