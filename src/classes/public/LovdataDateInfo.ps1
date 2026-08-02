# A date-bearing metadata value from a Lovdata document. Lovdata rarely publishes a clean single date:
# a field may carry several dates or a prose qualifier, so the raw text is always kept alongside any
# dates that could be parsed out of it, and the leftover prose is exposed as a note.
class LovdataDateInfo {
    # The unaltered text exactly as Lovdata published it, for example '1966-05-06 med virkning fra 1963-01-01'.
    [string] $Raw

    # Every ISO date found in the raw text, in the order they appear. Empty when none could be parsed.
    [datetime[]] $Dates = @()

    # The prose left over once the dates are removed, for example a qualifier or a parenthetical note.
    [string] $Note

    LovdataDateInfo() {}

    LovdataDateInfo([hashtable] $Properties) {
        foreach ($name in $Properties.Keys) {
            $this.$name = $Properties[$name]
        }
    }

    LovdataDateInfo([pscustomobject] $Object) {
        $known = [LovdataDateInfo].GetProperties().Name
        foreach ($property in $Object.PSObject.Properties) {
            if ($known -contains $property.Name) {
                $this.($property.Name) = $property.Value
            }
        }
    }

    [string] ToString() {
        return $this.Raw
    }
}
