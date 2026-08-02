# A section (a chapter or part) within a Lovdata document body. Sections nest, so a section holds both
# its own child sections and the articles directly under it. Nesting in the corpus reaches five levels
# deep, so the model recurses.
class LovdataSection {
    # The section heading text.
    [string] $Title

    # The nesting depth of the section, starting at 1 for a top-level section.
    [int] $Level

    # The child sections nested beneath this one.
    [object[]] $Sections = @()

    # The articles directly under this section.
    [object[]] $Articles = @()

    LovdataSection() {}

    LovdataSection([hashtable] $Properties) {
        foreach ($name in $Properties.Keys) {
            $this.$name = $Properties[$name]
        }
    }

    LovdataSection([pscustomobject] $Object) {
        $known = [LovdataSection].GetProperties().Name
        foreach ($property in $Object.PSObject.Properties) {
            if ($known -contains $property.Name) {
                $this.($property.Name) = $property.Value
            }
        }
    }

    [string] ToString() {
        return $this.Title
    }
}
