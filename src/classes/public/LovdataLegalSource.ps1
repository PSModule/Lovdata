# A legal source (base) in Lovdata's databases, such as Norwegian acts or central regulations.
class LovdataLegalSource {
    # The identifier used by the API to address the source, for example 'lov'.
    [string] $ID

    # The human readable name of the source, as Lovdata describes it.
    [string] $Description

    LovdataLegalSource() {}

    LovdataLegalSource([hashtable] $Properties) {
        foreach ($name in $Properties.Keys) {
            $this.$name = $Properties[$name]
        }
    }

    LovdataLegalSource([pscustomobject] $Object) {
        $known = [LovdataLegalSource].GetProperties().Name
        foreach ($property in $Object.PSObject.Properties) {
            if ($known -contains $property.Name) {
                $this.($property.Name) = $property.Value
            }
        }
    }

    [string] ToString() {
        return $this.ID
    }
}
