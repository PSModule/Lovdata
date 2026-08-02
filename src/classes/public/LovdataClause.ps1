# A single clause within a Lovdata article. A clause is a paragraph of legal text; a numbered clause also
# carries the number Lovdata assigned it.
class LovdataClause {
    # The clause number where Lovdata numbers it, otherwise null.
    [nullable[int]] $Number

    # The text of the clause.
    [string] $Text

    # The clause's in-document id.
    [string] $ID

    LovdataClause() {}

    LovdataClause([hashtable] $Properties) {
        foreach ($name in $Properties.Keys) {
            $this.$name = $Properties[$name]
        }
    }

    LovdataClause([pscustomobject] $Object) {
        $known = [LovdataClause].GetProperties().Name
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
