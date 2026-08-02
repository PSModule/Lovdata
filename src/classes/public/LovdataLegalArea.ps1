# A single legal area a Lovdata document is filed under. Lovdata organises areas as a hierarchy, so an
# area carries both its own identifier and name and the full path of segments from the root down to it.
# A document is often filed under more than one area.
class LovdataLegalArea {
    # The identifier of the leaf area, for example '09.03'.
    [string] $ID

    # The name of the leaf area, for example 'Fiskeri'.
    [string] $Name

    # The full path from the root area down to this one, each segment carrying its own ID and Name.
    [object[]] $Segments = @()

    # The segment names joined for display, for example 'Fiskeri- og fangstrett og havbruk > Fiskeri'.
    [string] $Path

    LovdataLegalArea() {}

    LovdataLegalArea([hashtable] $Properties) {
        foreach ($name in $Properties.Keys) {
            $this.$name = $Properties[$name]
        }
    }

    LovdataLegalArea([pscustomobject] $Object) {
        $known = [LovdataLegalArea].GetProperties().Name
        foreach ($property in $Object.PSObject.Properties) {
            if ($known -contains $property.Name) {
                $this.($property.Name) = $property.Value
            }
        }
    }

    [string] ToString() {
        return $this.Path
    }
}
