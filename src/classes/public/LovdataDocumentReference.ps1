# A reference from one Lovdata document to another, as found in fields such as the change history or the
# list of documents a document amends. The referenced document is identified by its RefID, and where
# Lovdata records when the reference took effect that date is kept as well.
class LovdataDocumentReference {
    # The RefID of the referenced document, for example 'lov/2023-06-16-40'.
    [string] $RefID

    # The human-readable text Lovdata showed for the reference.
    [string] $Text

    # The date associated with the reference where Lovdata records one, otherwise null.
    [nullable[datetime]] $Date

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
