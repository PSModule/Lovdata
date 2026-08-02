# Module-wide settings for the Lovdata module, stored in a module-scoped context so they are shared
# by every user context in the vault.
class LovdataConfig {
    # The ID of the context that holds this configuration.
    [string] $ID

    # The base URI new contexts connect to, for example 'https://api.lovdata.no'.
    [string] $ApiBaseUri

    # The name of the context used by commands that are not given one explicitly.
    [string] $DefaultContext

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
        return $this.ID
    }
}
