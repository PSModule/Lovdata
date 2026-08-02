function Save-LovdataPublicDataset {
    <#
        .SYNOPSIS
        Download a Lovdata public data package to disk.

        .DESCRIPTION
        Downloads one of the free open data packages Lovdata publishes to a directory on disk. The
        package is streamed straight to the file and the transfer is reported on the progress stream,
        because the packages are large. No account and no API key are needed. An existing file is not
        overwritten unless Force is given. The resulting file is returned so it can be piped on, for
        example to an extraction step.

        The packages are published under the Norwegian Licence for Open Government Data (NLOD) 2.0.
        Content retrieved through this command remains subject to Lovdata's terms; credit Lovdata as the
        source when redistributing it.

        .EXAMPLE
        Save-LovdataPublicDataset -FileName 'gjeldende-lover.tar.bz2'

        Downloads the current acts package into the current directory.

        .EXAMPLE
        Get-LovdataPublicDataset -FileName 'gjeldende-*' | Save-LovdataPublicDataset -Path 'C:\lovdata' -Force

        Downloads every matching package into the given directory, overwriting any existing files.

        .INPUTS
        LovdataPublicDataset

        .OUTPUTS
        System.IO.FileInfo

        .NOTES
        The packages are published under the Norwegian Licence for Open Government Data (NLOD) 2.0.

        .LINK
        https://psmodule.io/Lovdata/Functions/PublicData/Save-LovdataPublicDataset/

        .LINK
        https://psmodule.io/Lovdata/Functions/PublicData/Get-LovdataPublicDataset/
    #>
    [OutputType([System.IO.FileInfo])]
    [CmdletBinding(SupportsShouldProcess)]
    param(
        # The filename of the package to download, as reported by Get-LovdataPublicDataset.
        [Parameter(Mandatory, Position = 0, ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [ValidateScript(
            { $_ -eq [System.IO.Path]::GetFileName($_) -and $_ -notin '.', '..' },
            ErrorMessage = "FileName must be a bare package filename with no path separators, for example 'gjeldende-lover.tar.bz2'."
        )]
        [string] $FileName,

        # The directory to download the package into. Defaults to the current directory.
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string] $Path = '.',

        # Overwrite an existing file instead of refusing.
        [Parameter()]
        [switch] $Force
    )

    process {
        $directory = Resolve-Path -LiteralPath $Path -ErrorAction SilentlyContinue
        if ($null -eq $directory) {
            throw "The download directory [$Path] does not exist. Create it first, or pass an existing directory to -Path."
        }
        if (-not (Test-Path -LiteralPath $directory -PathType Container)) {
            throw "The download path [$Path] is not a directory. Pass a directory to -Path."
        }

        $target = Join-Path -Path $directory.ProviderPath -ChildPath $FileName

        if ((Test-Path -LiteralPath $target -PathType Leaf) -and -not $Force) {
            throw "A file already exists at [$target]. Use -Force to overwrite it."
        }

        if (-not $PSCmdlet.ShouldProcess($target, "Download Lovdata package [$FileName]")) {
            return
        }

        Invoke-LovdataDownload -Endpoint "/v1/publicData/get/$FileName" -OutFile $target

        Get-Item -LiteralPath $target
    }
}
