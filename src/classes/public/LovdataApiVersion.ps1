# The version of the deployed Lovdata API service, as reported by the '/version' endpoint.
class LovdataApiVersion {
    # The name of the deployment, for example 'lovdata-api'.
    [string] $Name

    # The build timestamp of the deployment, for example '2026-07-31-1613'.
    [string] $Timestamp

    # The source revision the deployment was built from.
    [string] $Revision

    LovdataApiVersion() {}

    LovdataApiVersion([hashtable] $Properties) {
        foreach ($name in $Properties.Keys) {
            $this.$name = $Properties[$name]
        }
    }

    LovdataApiVersion([pscustomobject] $Object) {
        $known = [LovdataApiVersion].GetProperties().Name
        foreach ($property in $Object.PSObject.Properties) {
            if ($known -contains $property.Name) {
                $this.($property.Name) = $property.Value
            }
        }
    }

    [string] ToString() {
        return '{0} {1}' -f $this.Name, $this.Timestamp
    }
}
