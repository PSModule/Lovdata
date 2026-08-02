# Module-wide settings for the Lovdata module, kept in memory for the current session.
class LovdataConfig {
    # The base URI the module sends requests to, for example 'https://api.lovdata.no'.
    [string] $ApiBaseUri

    LovdataConfig() {}

    LovdataConfig([hashtable] $Properties) {
        foreach ($name in $Properties.Keys) {
            $this.$name = $Properties[$name]
        }
    }

    LovdataConfig([pscustomobject] $Object) {
        $known = [LovdataConfig].GetProperties().Name
        foreach ($property in $Object.PSObject.Properties) {
            if ($known -contains $property.Name) {
                $this.($property.Name) = $property.Value
            }
        }
    }

    [string] ToString() {
        return $this.ApiBaseUri
    }
}
