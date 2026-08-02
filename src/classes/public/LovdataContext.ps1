# A stored Lovdata connection: the API key plus everything needed to reach the API with it.
# The key is kept as a SecureString so it is never held in memory or written to disk in clear text.
class LovdataContext {
    # The name the context is stored and selected by.
    [string] $ID

    # The base URI this context connects to, for example 'https://api.lovdata.no'.
    [string] $ApiBaseUri

    # The authentication scheme used against the API. Lovdata accepts an API key in the 'X-API-Key' header.
    [string] $AuthType

    # The Lovdata API key.
    [securestring] $ApiKey

    # When the API key was stored, so a stale context can be recognised.
    [System.Nullable[datetime]] $ConnectedAt

    LovdataContext() {}

    LovdataContext([hashtable] $Properties) {
        foreach ($name in $Properties.Keys) {
            $this.$name = $Properties[$name]
        }
    }

    LovdataContext([pscustomobject] $Object) {
        $known = [LovdataContext].GetProperties().Name
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
