function Get-LovdataLegalSource {
    <#
        .SYNOPSIS
        Get the legal sources available in Lovdata.

        .DESCRIPTION
        Returns the legal sources that the connected account can reach. A legal source is one of the bases
        Lovdata organises its documents into, such as acts and central regulations. Each source has the
        identifier other commands use to address it and the description Lovdata gives it. Note that
        Lovdata does not make every source in its databases available through the API.

        .EXAMPLE
        Get-LovdataLegalSource

        Returns every legal source the connected account can reach.

        .EXAMPLE
        Get-LovdataLegalSource -ID 'lov*'

        Returns the legal sources whose identifier starts with 'lov'.

        .EXAMPLE
        Get-LovdataLegalSource -Context 'production'

        Returns the legal sources reachable with the API key stored as 'production'.

        .INPUTS
        None

        .OUTPUTS
        LovdataLegalSource

        .NOTES
        Which sources are returned depends on the account, so the result can differ between contexts.

        .LINK
        https://psmodule.io/Lovdata/Functions/LegalSources/Get-LovdataLegalSource/

        .LINK
        https://api.lovdata.no/swagger/index.html
    #>
    [OutputType([LovdataLegalSource])]
    [CmdletBinding()]
    param(
        # The identifier of the legal sources to return. Supports wildcards.
        [Parameter(Position = 0)]
        [SupportsWildcards()]
        [ValidateNotNullOrEmpty()]
        [string] $ID = '*',

        # The connection to use, as a name or a context object. Defaults to the context commands use.
        [Parameter()]
        [object] $Context
    )

    $resolvedContext = Resolve-LovdataContext -Context $Context
    $response = Invoke-LovdataAPI -Endpoint '/v1/legalSource/list' -Method Get -Context $resolvedContext

    # The API documents the entries as free-form objects, so accept the field names it is known to use.
    $sources = foreach ($item in @($response)) {
        if ($null -eq $item) {
            continue
        }

        $properties = $item.PSObject.Properties
        $sourceID = ''
        foreach ($name in 'id', 'base', 'name') {
            if ($properties[$name]) {
                $sourceID = [string]$properties[$name].Value
                break
            }
        }

        $description = ''
        foreach ($name in 'description', 'title') {
            if ($properties[$name]) {
                $description = [string]$properties[$name].Value
                break
            }
        }

        [LovdataLegalSource]@{
            ID          = $sourceID
            Description = $description
        }
    }

    $sources | Where-Object { $_.ID -like $ID } | Sort-Object -Property ID
}
