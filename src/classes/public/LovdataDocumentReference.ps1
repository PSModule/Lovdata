# A reference from one Lovdata document to another, as found in fields such as the change history or the
# list of documents a document amends. The referenced document is identified by its RefID. Where the
# field states when the referenced change took effect, that per-reference date is kept in InForceFrom.
class LovdataDocumentReference {
    # The RefID of the referenced document, for example 'lov/2023-06-16-40'.
    [string] $RefID

    # The human-readable text Lovdata showed for the reference.
    [string] $Text

    # The date embedded in this reference's own RefID, for example 2023-06-16 for 'lov/2023-06-16-40',
    # or null when the RefID carries no date. It is always derived from this reference, never from a
    # neighbouring one.
    [nullable[datetime]] $Date

    # The date the referenced change took effect, read from a per-reference 'fra <date>' qualifier in the
    # field, otherwise null. This is specific to the reference it follows and is not recoverable elsewhere.
    [nullable[datetime]] $InForceFrom

    LovdataDocumentReference() {}

    LovdataDocumentReference([hashtable] $Properties) {
        foreach ($name in $Properties.Keys) {
            $this.$name = $Properties[$name]
        }
    }

    LovdataDocumentReference([pscustomobject] $Object) {
        $known = [LovdataDocumentReference].GetProperties().Name
        foreach ($property in $Object.PSObject.Properties) {
            if ($known -contains $property.Name) {
                $this.($property.Name) = $property.Value
            }
        }
    }

    [string] ToString() {
        return $this.RefID
    }
}
