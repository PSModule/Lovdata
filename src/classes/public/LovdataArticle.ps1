# An article (a paragraph, in Norwegian legal terms) within a Lovdata document. It holds the article's
# identity and heading plus its clauses, lists, footnotes, and change notes.
class LovdataArticle {
    # The article's short name from Lovdata's data-name attribute, for example a paragraph sign followed by 1.
    [string] $Name

    # The article number as shown in the heading, for example a paragraph sign followed by ' 1'.
    [string] $Number

    # The article's title where it has one.
    [string] $Title

    # The article's in-document id.
    [string] $ID

    # The Lovdata URL of the article from its data-lovdata-URL attribute.
    [string] $Url

    # The clauses that make up the article.
    [object[]] $Clauses = @()

    # The lists within the article.
    [object[]] $Lists = @()

    # The footnotes attached to the article.
    [object[]] $Footnotes = @()

    # The change notes recording how the article has been amended.
    [object[]] $ChangeNotes = @()

    LovdataArticle() {}

    LovdataArticle([hashtable] $Properties) {
        foreach ($name in $Properties.Keys) {
            $this.$name = $Properties[$name]
        }
    }

    LovdataArticle([pscustomobject] $Object) {
        $known = [LovdataArticle].GetProperties().Name
        foreach ($property in $Object.PSObject.Properties) {
            if ($known -contains $property.Name) {
                $this.($property.Name) = $property.Value
            }
        }
    }

    [string] ToString() {
        if ([string]::IsNullOrWhiteSpace($this.Title)) {
            return $this.Number
        }
        return '{0} {1}' -f $this.Number, $this.Title
    }
}
