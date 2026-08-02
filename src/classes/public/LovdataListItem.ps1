# A single item in a Lovdata list. The marker is the label Lovdata prints in front of the item, for
# example '1.' or 'a)', kept separately from the item's text.
class LovdataListItem {
    # The marker Lovdata prints in front of the item, for example '1.'.
    [string] $Marker

    # The text of the item.
    [string] $Text

    # The item's in-document id.
    [string] $ID

    LovdataListItem() {}

    LovdataListItem([hashtable] $Properties) {
        foreach ($name in $Properties.Keys) {
            $this.$name = $Properties[$name]
        }
    }

    LovdataListItem([pscustomobject] $Object) {
        $known = [LovdataListItem].GetProperties().Name
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
