function ConvertTo-LovdataXmlDocument {
    <#
        .SYNOPSIS
        Load a Lovdata archive document into an XML document.

        .DESCRIPTION
        Lovdata's archive documents are XHTML with a leading HTML doctype that a standard XML parser
        rejects. This helper strips that doctype and normalises self-closing line breaks to newlines, then
        loads the result into a System.Xml.XmlDocument. Every document in the open corpus loads this way,
        so no HTML-tolerant parser is needed.

        .EXAMPLE
        ConvertTo-LovdataXmlDocument -Text (Get-Content -LiteralPath $file -Raw)

        Loads the raw text of an archive document into an XML document.

        .INPUTS
        System.String

        .OUTPUTS
        System.Xml.XmlDocument

        .NOTES
        The doctype is stripped rather than resolved because Lovdata publishes the documents as XHTML.

        .LINK
        https://api.lovdata.no/om-api-tjenesten/
    #>
    [OutputType([System.Xml.XmlDocument])]
    [CmdletBinding()]
    param(
        # The raw text of an archive document.
        [Parameter(Mandatory, ValueFromPipeline)]
        [ValidateNotNullOrEmpty()]
        [string] $Text
    )

    process {
        $cleaned = $Text -replace '^\s*<!DOCTYPE[^>]*>', ''
        # Keep line breaks as text so InnerText does not glue words together across a <br />.
        $cleaned = $cleaned -replace '<br\s*/?>', "`n"

        $document = [System.Xml.XmlDocument]::new()
        $document.LoadXml($cleaned)
        $document
    }
}
