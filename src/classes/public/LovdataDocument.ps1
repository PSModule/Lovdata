# A Lovdata document (an act or a regulation) as a PowerShell object. It carries every metadata field
# Lovdata publishes in the document key-info block, and, when parsed from an archive, the full body as a
# recursive tree of sections and articles. When rebuilt from the bundled index the metadata is present
# and the body collections are empty.
class LovdataDocument {
    # The full title, for example 'Lov om folketrygd (folketrygdloven)'.
    [string] $Title

    # The short title Lovdata assigns, for example 'Folketrygdloven'.
    [string] $TitleShort

    # The legacy identifier, for example 'LOV-1997-02-28-19'.
    [string] $LegacyID

    # The bare document id with the legacy prefix removed, for example '1997-02-28-19'.
    [string] $LawID

    # The RefID, for example 'lov/1997-02-28-19'.
    [string] $RefID

    # The document id including the source, for example 'NL/lov/1997-02-28-19'.
    [string] $DokID

    # The responsible ministries. A list, though only one document uses more than one entry.
    [string[]] $Ministry = @()

    # The legal areas the document is filed under, each a hierarchical path.
    [object[]] $LegalAreas = @()

    # When the document entered into force, with the raw text preserved.
    [LovdataDateInfo] $DateInForce

    # When the document was last updated, always carrying an explanatory note.
    [LovdataDateInfo] $LastUpdated

    # The changes that last amended the document, as references.
    [object[]] $LastChangedBy = @()

    # When the last change entered into force.
    [LovdataDateInfo] $LastChangeInForce

    # Miscellaneous information Lovdata records, as text.
    [string] $MiscInformation

    # When the document was published.
    [LovdataDateInfo] $DateOfPublication

    # The documents this document changes, as references.
    [object[]] $ChangesToDocuments = @()

    # The EEA agreement references Lovdata records, as text.
    [string] $EeaReferences

    # What the document applies to, as text. Present on very few documents.
    [string] $AppliesTo

    # The table of contents as a tree of entries.
    [object[]] $TableOfContents = @()

    # The source the document comes from, for example 'nl' for acts or 'sf' for central regulations.
    [string] $Source

    # The name of the archive file the document was parsed from.
    [string] $SourceFile

    # The top-level sections of the document body. Empty when built from the bundled index.
    [object[]] $Sections = @()

    # The articles directly under the document body, outside any section.
    [object[]] $Articles = @()

    # Clauses that sit directly under the document body, outside any article.
    [object[]] $Clauses = @()

    # The document-level footnotes.
    [object[]] $Footnotes = @()

    LovdataDocument() {}

    LovdataDocument([hashtable] $Properties) {
        foreach ($name in $Properties.Keys) {
            $this.$name = $Properties[$name]
        }
    }

    LovdataDocument([pscustomobject] $Object) {
        $known = [LovdataDocument].GetProperties().Name
        foreach ($property in $Object.PSObject.Properties) {
            if ($known -notcontains $property.Name) {
                continue
            }
            $this.($property.Name) = $property.Value
        }

        # The bundled index is JSON, so nested records arrive as untyped objects. Rebuild the typed
        # metadata shapes so a document restored from the index is indistinguishable from a parsed one.
        $this.LegalAreas = [LovdataDocument]::AsTyped($this.LegalAreas, [LovdataLegalArea])
        $this.LastChangedBy = [LovdataDocument]::AsTyped($this.LastChangedBy, [LovdataDocumentReference])
        $this.ChangesToDocuments = [LovdataDocument]::AsTyped($this.ChangesToDocuments, [LovdataDocumentReference])
        $this.TableOfContents = [LovdataDocument]::AsTyped($this.TableOfContents, [LovdataTocEntry])
        $this.DateInForce = [LovdataDocument]::AsDate($this.DateInForce)
        $this.LastUpdated = [LovdataDocument]::AsDate($this.LastUpdated)
        $this.LastChangeInForce = [LovdataDocument]::AsDate($this.LastChangeInForce)
        $this.DateOfPublication = [LovdataDocument]::AsDate($this.DateOfPublication)
    }

    # Rebuild a collection of untyped index records into instances of the given class.
    hidden static [object[]] AsTyped([object] $Value, [type] $Type) {
        if ($null -eq $Value) {
            return @()
        }
        $result = foreach ($item in @($Value)) {
            if ($null -eq $item -or $item -is $Type) {
                $item
            } else {
                $Type::new([pscustomobject]$item)
            }
        }
        return @($result)
    }

    # Rebuild a single untyped date record into a LovdataDateInfo.
    hidden static [LovdataDateInfo] AsDate([object] $Value) {
        if ($null -eq $Value -or $Value -is [LovdataDateInfo]) {
            return $Value
        }
        return [LovdataDateInfo]::new([pscustomobject]$Value)
    }

    [string] ToString() {
        if (-not [string]::IsNullOrWhiteSpace($this.Title)) {
            return $this.Title
        }
        return $this.RefID
    }
}
