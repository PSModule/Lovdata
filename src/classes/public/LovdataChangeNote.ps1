# A change note attached to a Lovdata article, recording how the article has been amended. The note text
# is kept as published, and any documents it links to are exposed as references.
class LovdataChangeNote {
    # The text of the change note.
    [string] $Text

    # The documents the note links to.
    [object[]] $References = @()

    LovdataChangeNote() {}

    LovdataChangeNote([hashtable] $Properties) {
        foreach ($name in $Properties.Keys) {
            $this.$name = $Properties[$name]
        }
    }

    LovdataChangeNote([pscustomobject] $Object) {
        $known = [LovdataChangeNote].GetProperties().Name
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
