# A list within a Lovdata article. Lovdata renders both ordered and unordered lists; the Ordered flag
# records which, and the items keep their own markers.
class LovdataList {
    # Whether the list is ordered (an 'ol') rather than a bullet list (a 'ul').
    [bool] $Ordered

    # The items in the list.
    [object[]] $Items = @()

    LovdataList() {}

    LovdataList([hashtable] $Properties) {
        foreach ($name in $Properties.Keys) {
            $this.$name = $Properties[$name]
        }
    }

    LovdataList([pscustomobject] $Object) {
        $known = [LovdataList].GetProperties().Name
        foreach ($property in $Object.PSObject.Properties) {
            if ($known -contains $property.Name) {
                $this.($property.Name) = $property.Value
            }
        }
    }

    [string] ToString() {
        return "$($this.Items.Count) items"
    }
}
