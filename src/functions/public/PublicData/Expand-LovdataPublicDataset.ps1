function Expand-LovdataPublicDataset {
    <#
        .SYNOPSIS
        Unpack a downloaded Lovdata public data package.

        .DESCRIPTION
        Extracts a downloaded Lovdata .tar.bz2 package into a directory using the tar tool that ships with
        PowerShell 7 on Windows, macOS, and Linux. A package expands into one or more source folders, for
        example 'nl' for acts and 'sf' for central regulations, so the destination directory is returned
        for a caller to enumerate or pass on to Get-LovdataDocument. An existing destination is reused
        unless Force is given, in which case it is recreated.

        The packages are published under the Norwegian Licence for Open Government Data (NLOD) 2.0. Content
        retrieved through this command remains subject to Lovdata's terms; credit Lovdata as the source
        when redistributing it.

        .EXAMPLE
        Expand-LovdataPublicDataset -Path 'gjeldende-lover.tar.bz2'

        Unpacks the package into a directory named after it and returns that directory.

        .EXAMPLE
        Save-LovdataPublicDataset -FileName 'gjeldende-lover.tar.bz2' | Expand-LovdataPublicDataset

        Downloads a package and unpacks it in one pipeline.

        .INPUTS
        System.IO.FileInfo

        .OUTPUTS
        System.IO.DirectoryInfo

        .NOTES
        The packages are published under the Norwegian Licence for Open Government Data (NLOD) 2.0.

        .LINK
        https://psmodule.io/Lovdata/Functions/PublicData/Expand-LovdataPublicDataset/

        .LINK
        https://psmodule.io/Lovdata/Functions/PublicData/Save-LovdataPublicDataset/
    #>
    [OutputType([System.IO.DirectoryInfo])]
    [CmdletBinding(SupportsShouldProcess)]
    param(
        # The path to the downloaded .tar.bz2 package.
        [Parameter(Mandatory, Position = 0, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [Alias('FullName')]
        [ValidateNotNullOrEmpty()]
        [string] $Path,

        # The directory to unpack into. Defaults to a directory named after the package, next to it.
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string] $DestinationPath,

        # Recreate the destination directory if it already exists.
        [Parameter()]
        [switch] $Force
    )

    process {
        $archive = Resolve-Path -LiteralPath $Path -ErrorAction SilentlyContinue
        if ($null -eq $archive) {
            throw "The package [$Path] does not exist. Download it first with Save-LovdataPublicDataset."
        }
        $archivePath = $archive.ProviderPath

        if ($PSBoundParameters.ContainsKey('DestinationPath')) {
            $destination = $DestinationPath
        } else {
            $baseName = [System.IO.Path]::GetFileName($archivePath) -replace '\.tar\.bz2$', ''
            $destination = Join-Path -Path (Split-Path -Path $archivePath -Parent) -ChildPath $baseName
        }

        if ((Test-Path -LiteralPath $destination) -and $Force) {
            if ($PSCmdlet.ShouldProcess($destination, 'Remove the existing destination directory')) {
                Remove-Item -LiteralPath $destination -Recurse -Force
            }
        }

        if (-not (Test-Path -LiteralPath $destination)) {
            $null = New-Item -Path $destination -ItemType Directory -Force
        }

        if (-not $PSCmdlet.ShouldProcess($destination, "Unpack Lovdata package [$archivePath]")) {
            return
        }

        # tar ships with PowerShell 7 on every supported OS and reads bzip2 archives with -j.
        & tar -xjf $archivePath -C $destination
        if ($LASTEXITCODE -ne 0) {
            throw "Unpacking [$archivePath] failed. tar exited with code [$LASTEXITCODE]."
        }

        Get-Item -LiteralPath $destination
    }
}
