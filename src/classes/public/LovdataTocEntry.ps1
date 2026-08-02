# An entry in a Lovdata document's table of contents. Entries nest, so each one can carry its own child
# entries, mirroring the chapter and paragraph structure of the document body.
class LovdataTocEntry {
    # The text of the entry as shown in the table of contents.
    [string] $Title

    # The in-document anchor the entry links to, for example '#dokument'.
    [string] $Anchor

    # The child entries nested beneath this one.
    [object[]] $Children = @()

    LovdataTocEntry() {}

    LovdataTocEntry([hashtable] $Properties) {
        foreach ($name in $Properties.Keys) {
            $this.$name = $Properties[$name]
        }
    }

    LovdataTocEntry([pscustomobject] $Object) {
        $known = [LovdataTocEntry].GetProperties().Name
        foreach ($property in $Object.PSObject.Properties) {
            if ($known -contains $property.Name) {
                $this.($property.Name) = $property.Value
            }
        }

        # Entries nest, so rebuild any children the index round-trip handed over as untyped objects.
        $rebuilt = foreach ($child in @($this.Children)) {
            if ($null -eq $child -or $child -is [LovdataTocEntry]) {
                $child
            } else {
                [LovdataTocEntry]::new([pscustomobject]$child)
            }
        }
        $this.Children = @($rebuilt)
    }

    [string] ToString() {
        return $this.Title
    }
}
