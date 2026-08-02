function Get-LovdataDocument {
    <#
        .SYNOPSIS
        Get a Lovdata document from the bundled index or from an extracted archive.

        .DESCRIPTION
        Returns Lovdata documents as objects. By default it reads the metadata-only index the module
        ships, so a lookup needs no network access and no unpacking. Given the path to an extracted
        archive it instead parses the XML documents in full, returning the complete object hierarchy:
        metadata plus the chapter and paragraph structure, clauses, lists, footnotes, and change notes.

        In both modes the RefID can be used to select documents, and it accepts wildcards. When reading an
        archive the path may be a directory holding one or more source folders, a single source folder, or
        a single document file.

        .EXAMPLE
        Get-LovdataDocument -RefID 'lov/1997-02-28-19'

        Returns the folketrygdloven record from the bundled index.

        .EXAMPLE
        Get-LovdataDocument -Path './gjeldende-lover' -RefID 'lov/1902-*'

        Parses the matching documents from an extracted archive in full fidelity.

        .INPUTS
        System.String

        .OUTPUTS
        LovdataDocument

        .NOTES
        The bundled index omits the table of contents and document body; parse an archive for full
        fidelity.

        .LINK
        https://psmodule.io/Lovdata/Functions/Documents/Get-LovdataDocument/

        .LINK
        https://psmodule.io/Lovdata/Functions/Documents/Find-LovdataDocument/
    #>
    [OutputType([LovdataDocument])]
    [CmdletBinding(DefaultParameterSetName = 'From the bundled index')]
    param(
        # The RefID to select, for example 'lov/1997-02-28-19'. Supports wildcards.
        [Parameter(Position = 0, ParameterSetName = 'From the bundled index', ValueFromPipelineByPropertyName)]
        [Parameter(Position = 0, ParameterSetName = 'From an extracted archive', ValueFromPipelineByPropertyName)]
        [SupportsWildcards()]
        [ValidateNotNullOrEmpty()]
        [string] $RefID = '*',

        # The path to an extracted archive directory, a source folder, or a single document file.
        [Parameter(Mandatory, ParameterSetName = 'From an extracted archive', ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [Alias('FullName')]
        [ValidateNotNullOrEmpty()]
        [string] $Path
    )

    process {
        if ($PSCmdlet.ParameterSetName -eq 'From the bundled index') {
            Import-LovdataIndexData | Where-Object { $_.RefID -like $RefID }
            return
        }

        $resolved = Resolve-Path -LiteralPath $Path -ErrorAction SilentlyContinue
        if ($null -eq $resolved) {
            throw "The path [$Path] does not exist. Unpack a package first with Expand-LovdataPublicDataset."
        }
        $target = $resolved.ProviderPath

        $files = if (Test-Path -LiteralPath $target -PathType Leaf) {
            @([System.IO.FileInfo]::new($target))
        } else {
            Get-ChildItem -LiteralPath $target -Recurse -Filter *.xml -File
        }

        foreach ($file in $files) {
            $xml = ConvertTo-LovdataXmlDocument -Text (Get-Content -LiteralPath $file.FullName -Raw)
            $document = ConvertFrom-LovdataMetadata -Document $xml
            if ($document.RefID -notlike $RefID) {
                continue
            }

            $document.Source = Split-Path -Path (Split-Path -Path $file.FullName -Parent) -Leaf
            $document.SourceFile = $file.Name

            $body = ConvertFrom-LovdataBody -Document $xml
            $document.Sections = $body.Sections
            $document.Articles = $body.Articles
            $document.Clauses = $body.Clauses
            $document.Footnotes = $body.Footnotes

            $document
        }
    }
}
