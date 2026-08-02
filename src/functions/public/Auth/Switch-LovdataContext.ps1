function Switch-LovdataContext {
    <#
        .SYNOPSIS
        Choose which stored Lovdata connection commands use by default.

        .DESCRIPTION
        Points the module at another stored connection, so commands that are not given a context use it
        from then on. The context has to exist; switching to a name that was never stored fails rather
        than leaving the module pointing at nothing.

        .EXAMPLE
        Switch-LovdataContext -Context 'production'

        Makes 'production' the connection commands use by default.

        .EXAMPLE
        Switch-LovdataContext -Context 'test' -PassThru

        Switches to 'test' and returns the context that is now in use.

        .INPUTS
        LovdataContext

        .INPUTS
        System.String

        .OUTPUTS
        LovdataContext

        .NOTES
        A single command can still target another connection with its own Context parameter.

        .LINK
        https://psmodule.io/Lovdata/Functions/Auth/Switch-LovdataContext/

        .LINK
        https://psmodule.io/Lovdata/Functions/Auth/Get-LovdataContext/
    #>
    [OutputType([LovdataContext])]
    [CmdletBinding(SupportsShouldProcess)]
    param(
        # The context to use by default, as a name or a context object.
        [Parameter(Mandatory, Position = 0, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [ValidateNotNull()]
        [Alias('ID', 'Name')]
        [object] $Context,

        # Return the context that is now in use.
        [Parameter()]
        [switch] $PassThru
    )

    process {
        $name = if ($Context -is [LovdataContext]) { $Context.ID } else { [string]$Context }

        # Resolving first means a typo fails here instead of on the next API call.
        $target = Get-LovdataContext -Context $name

        if ($PSCmdlet.ShouldProcess("Lovdata context [$name]", 'Use as the default context')) {
            Set-LovdataConfig -Name DefaultContext -Value $name -Confirm:$false

            if ($PassThru) {
                $target
            }
        }
    }
}
