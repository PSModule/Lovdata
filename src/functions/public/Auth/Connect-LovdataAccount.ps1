#Requires -Modules @{ ModuleName = 'Context'; ModuleVersion = '8.1.6' }

function Connect-LovdataAccount {
    <#
        .SYNOPSIS
        Store a Lovdata API key so later commands can use it.

        .DESCRIPTION
        Saves a Lovdata API key in an encrypted context and remembers which API it belongs to. Every
        command that talks to Lovdata picks the key up from there, so scripts never have to carry it.
        Storing more than one context keeps several accounts available at the same time; the first one
        stored becomes the default, and Default moves the default to another one.

        Lovdata issues API keys to users holding the 'api' role. The key is sent as the 'X-API-Key'
        header on every request.

        .EXAMPLE
        Connect-LovdataAccount -ApiKey (Read-Host -Prompt 'Lovdata API key' -AsSecureString)

        Stores the key under the default context name.

        .EXAMPLE
        Connect-LovdataAccount -ApiKey $key -Context 'production' -Default

        Stores the key as 'production' and makes it the context commands use by default.

        .EXAMPLE
        Connect-LovdataAccount -ApiKey $key -ApiBaseUri 'https://api.lovdata.no' -PassThru

        Stores the key against an explicit API base URI and returns the stored context.

        .INPUTS
        None

        .OUTPUTS
        LovdataContext

        .NOTES
        The key is encrypted at rest by the Context module and is never written to the output stream.

        .LINK
        https://psmodule.io/Lovdata/Functions/Auth/Connect-LovdataAccount/

        .LINK
        https://psmodule.io/Lovdata/Functions/Auth/Disconnect-LovdataAccount/

        .LINK
        https://api.lovdata.no/swagger/index.html
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute(
        'PSAvoidUsingConvertToSecureStringWithPlainText', '',
        Justification = 'A plain string key is accepted for convenience and converted before it is stored.'
    )]
    [OutputType([LovdataContext])]
    [CmdletBinding(SupportsShouldProcess)]
    param(
        # The Lovdata API key, as a SecureString or as a string.
        [Parameter(Mandatory, Position = 0)]
        [ValidateScript(
            {
                ($_ -is [securestring] -and $_.Length -gt 0) -or
                ($_ -is [string] -and -not [string]::IsNullOrWhiteSpace($_))
            },
            ErrorMessage = 'The API key must be a non-empty string or a non-empty SecureString.'
        )]
        [Alias('Key')]
        [object] $ApiKey,

        # The name to store the connection under.
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [Alias('Name')]
        [string] $Context = 'default',

        # The base URI of the Lovdata API this key belongs to. Defaults to the module setting.
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string] $ApiBaseUri,

        # Make this the context commands use by default, replacing any existing default.
        [Parameter()]
        [switch] $Default,

        # Return the stored context.
        [Parameter()]
        [switch] $PassThru
    )

    Initialize-LovdataConfig

    if ($Context -eq $script:Lovdata.Config.ID) {
        throw "The context name [$($script:Lovdata.Config.ID)] is reserved for the Lovdata module settings. Choose another name."
    }

    if (-not $PSBoundParameters.ContainsKey('ApiBaseUri')) {
        $ApiBaseUri = $script:Lovdata.Config.ApiBaseUri
    }

    if (-not $PSCmdlet.ShouldProcess("Lovdata context [$Context]", 'Store the API key')) {
        return
    }

    $secureApiKey = if ($ApiKey -is [securestring]) {
        $ApiKey
    } else {
        ConvertTo-SecureString -String $ApiKey -AsPlainText -Force
    }

    $contextObject = [LovdataContext]@{
        ID          = $Context
        ApiBaseUri  = $ApiBaseUri
        AuthType    = 'APIKey'
        ApiKey      = $secureApiKey
        ConnectedAt = Get-Date
    }

    $null = Set-Context -ID $Context -Context $contextObject -Vault $script:Lovdata.ContextVault

    if ($Default -or [string]::IsNullOrWhiteSpace($script:Lovdata.Config.DefaultContext)) {
        Set-LovdataConfig -Name DefaultContext -Value $Context -Confirm:$false
    }

    if ($PassThru) {
        Get-LovdataContext -Context $Context
    }
}
