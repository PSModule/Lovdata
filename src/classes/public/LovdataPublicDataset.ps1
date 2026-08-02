# A public data package Lovdata publishes as free open data, such as the current acts or regulations.
class LovdataPublicDataset {
    # The name of the package file, for example 'gjeldende-lover.tar.bz2'.
    [string] $FileName

    # The description Lovdata gives the package.
    [string] $Description

    # The size of the package in bytes.
    [long] $SizeBytes

    # When the package was last updated.
    [datetime] $LastModified

    LovdataPublicDataset() {}

    LovdataPublicDataset([hashtable] $Properties) {
        foreach ($name in $Properties.Keys) {
            $this.$name = $Properties[$name]
        }
    }

    LovdataPublicDataset([pscustomobject] $Object) {
        $known = [LovdataPublicDataset].GetProperties().Name
        foreach ($property in $Object.PSObject.Properties) {
            if ($known -contains $property.Name) {
                $this.($property.Name) = $property.Value
            }
        }
    }

    [string] ToString() {
        return $this.FileName
    }
}
