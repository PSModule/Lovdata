function ConvertFrom-LovdataBody {
    <#
        .SYNOPSIS
        Parse a Lovdata document body into a section and article tree.

        .DESCRIPTION
        Walks the document body of a Lovdata archive document and builds the chapter and paragraph
        structure as objects. Sections nest, so the walk recurses; nesting in the corpus reaches five
        levels deep. Each article keeps its clauses, lists, footnotes, and change notes, and the raw
        identity attributes Lovdata records. The result carries the top-level sections and articles, any
        clauses directly under the body, and the document-level footnotes.

        .EXAMPLE
        ConvertFrom-LovdataBody -Document $xml

        Returns the parsed body of the given XML document.

        .INPUTS
        System.Xml.XmlDocument

        .OUTPUTS
        System.Management.Automation.PSObject

        .NOTES
        Elements are recognised by their tag and class, the combinations of which were enumerated across
        the whole corpus.

        .LINK
        https://api.lovdata.no/om-api-tjenesten/
    #>
    [OutputType([pscustomobject])]
    [CmdletBinding()]
    param(
        # The XML document of a Lovdata archive document.
        [Parameter(Mandatory, ValueFromPipeline)]
        [ValidateNotNull()]
        [System.Xml.XmlDocument] $Document
    )

    process {
        $headingXPath = "*[local-name()='h1' or local-name()='h2' or local-name()='h3' or " +
        "local-name()='h4' or local-name()='h5' or local-name()='h6']"
        $clauseClasses = @('legalP', 'numberedLegalP', 'defaultP', 'footnoteLegalP', 'centeredP', 'leddfortsettelse')

        $buildClause = {
            param($node)
            $numerator = $node.GetAttribute('data-numerator')
            [LovdataClause]@{
                Number = if ($numerator) { $numerator } else { $null }
                Text   = $node.InnerText.Trim()
                ID     = $node.GetAttribute('id')
            }
        }

        $buildList = {
            param($node)
            $items = foreach ($li in $node.SelectNodes("*[local-name()='li']")) {
                [LovdataListItem]@{
                    Marker = $li.GetAttribute('data-name')
                    Text   = $li.InnerText.Trim()
                    ID     = $li.GetAttribute('id')
                }
            }
            [LovdataList]@{
                Ordered = $node.LocalName -eq 'ol'
                Items   = @($items)
            }
        }

        $buildArticle = {
            param($node)
            $article = [LovdataArticle]@{
                Name = $node.GetAttribute('data-name')
                ID   = $node.GetAttribute('id')
                Url  = $node.GetAttribute('data-lovdata-URL')
            }

            $header = $node.SelectSingleNode("*[contains(@class,'legalArticleHeader')]")
            if ($header) {
                $value = $header.SelectSingleNode(".//*[@class='legalArticleValue']")
                $title = $header.SelectSingleNode(".//*[@class='legalArticleTitle']")
                $article.Number = if ($value) { $value.InnerText.Trim() } else { $header.InnerText.Trim() }
                if ($title) {
                    $article.Title = $title.InnerText.Trim()
                }
            }

            $clauses = [System.Collections.Generic.List[object]]::new()
            $lists = [System.Collections.Generic.List[object]]::new()
            $changes = [System.Collections.Generic.List[object]]::new()

            foreach ($child in $node.ChildNodes) {
                if ($child.NodeType -ne 'Element') {
                    continue
                }
                $class = $child.GetAttribute('class')
                if ($child.LocalName -in 'ol', 'ul' -and $class -match 'defaultList') {
                    $lists.Add((& $buildList $child))
                } elseif ($class -eq 'changesToParent' -or $class -eq 'change' -or $class -eq 'document-change') {
                    $refs = foreach ($a in $child.SelectNodes(".//*[local-name()='a']")) {
                        [LovdataDocumentReference]@{ RefID = $a.GetAttribute('href'); Text = $a.InnerText.Trim() }
                    }
                    $changes.Add([LovdataChangeNote]@{ Text = $child.InnerText.Trim(); References = @($refs) })
                } elseif ($class -in $clauseClasses) {
                    $clauses.Add((& $buildClause $child))
                }
            }

            $footnotes = foreach ($fn in $node.SelectNodes(".//*[local-name()='article'][@class='footnote']")) {
                $label = $fn.SelectSingleNode(".//*[@class='footnoteLabel']")
                [LovdataFootnote]@{
                    Label = if ($label) { $label.InnerText.Trim() } else { $fn.GetAttribute('data-name') }
                    Text  = $fn.InnerText.Trim()
                }
            }

            $article.Clauses = @($clauses)
            $article.Lists = @($lists)
            $article.ChangeNotes = @($changes)
            $article.Footnotes = @($footnotes)
            $article
        }

        $buildSection = {
            param($node, $level)
            $section = [LovdataSection]@{ Level = $level }
            $heading = $node.SelectSingleNode($headingXPath)
            if ($heading) {
                $section.Title = $heading.InnerText.Trim()
            }

            $sections = [System.Collections.Generic.List[object]]::new()
            $articles = [System.Collections.Generic.List[object]]::new()
            foreach ($child in $node.ChildNodes) {
                if ($child.NodeType -ne 'Element') {
                    continue
                }
                $class = $child.GetAttribute('class')
                if ($class -eq 'section') {
                    $sections.Add((& $buildSection $child ($level + 1)))
                } elseif ($class -in 'legalArticle', 'futureLegalArticle', 'marginIdArticle') {
                    $articles.Add((& $buildArticle $child))
                }
            }
            $section.Sections = @($sections)
            $section.Articles = @($articles)
            $section
        }

        $body = $Document.SelectSingleNode("//*[local-name()='main'][@class='documentBody']")
        $sections = [System.Collections.Generic.List[object]]::new()
        $articles = [System.Collections.Generic.List[object]]::new()
        $clauses = [System.Collections.Generic.List[object]]::new()

        if ($null -ne $body) {
            foreach ($child in $body.ChildNodes) {
                if ($child.NodeType -ne 'Element') {
                    continue
                }
                $class = $child.GetAttribute('class')
                if ($class -eq 'section') {
                    $sections.Add((& $buildSection $child 1))
                } elseif ($class -in 'legalArticle', 'futureLegalArticle', 'marginIdArticle') {
                    $articles.Add((& $buildArticle $child))
                } elseif ($class -in $clauseClasses) {
                    $clauses.Add((& $buildClause $child))
                }
            }
        }

        $footnoteXPath = "//*[local-name()='footer'][@class='footnotes']" +
        "//*[local-name()='article'][@class='footnote']"
        $footnotes = foreach ($fn in $Document.SelectNodes($footnoteXPath)) {
            $label = $fn.SelectSingleNode(".//*[@class='footnoteLabel']")
            [LovdataFootnote]@{
                Label = if ($label) { $label.InnerText.Trim() } else { $fn.GetAttribute('data-name') }
                Text  = $fn.InnerText.Trim()
            }
        }

        [pscustomobject]@{
            Sections  = @($sections)
            Articles  = @($articles)
            Clauses   = @($clauses)
            Footnotes = @($footnotes)
        }
    }
}
