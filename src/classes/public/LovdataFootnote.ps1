# A footnote from a Lovdata document. The label is the printed marker (for example '1') that inline
# footnote references point at; the text is the footnote body.
class LovdataFootnote {
    # The printed label of the footnote, for example '1'.
    [string] $Label

    # The text of the footnote.
    [string] $Text

    LovdataFootnote() {}

    LovdataFootnote([hashtable] $Properties) {
        foreach ($name in $Properties.Keys) {
            $this.$name = $Properties[$name]
        }
    }

    LovdataFootnote([pscustomobject] $Object) {
        $known = [LovdataFootnote].GetProperties().Name
        foreach ($property in $Object.PSObject.Properties) {
            if ($known -contains $property.Name) {
                $this.($property.Name) = $property.Value
            }
        }
    }

    [string] ToString() {
        return $this.Text
    }
}
