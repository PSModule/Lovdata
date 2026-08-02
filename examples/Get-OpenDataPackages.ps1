<#
    .SYNOPSIS
    Download the current Norwegian acts and regulations and unpack them locally.

    .DESCRIPTION
    Lists Lovdata's free open data packages, downloads the current acts and central regulations into a
    local folder, and unpacks the .tar.bz2 archives with the tar tool that ships with PowerShell 7.
    No account and no API key are needed. The unpacked content is published under NLOD 2.0; credit
    Lovdata as the source when you redistribute it.
#>

Import-Module -Name Lovdata

$destination = Join-Path -Path (Get-Location) -ChildPath 'lovdata'
$null = New-Item -Path $destination -ItemType Directory -Force

# See what Lovdata publishes, with the size and last-modified date of each package.
Get-LovdataPublicDataset | Format-Table -Property FileName, SizeBytes, LastModified

# Download the current acts and central regulations, overwriting any earlier copies.
$packages = Get-LovdataPublicDataset -FileName 'gjeldende-*' |
    Save-LovdataPublicDataset -Path $destination -Force

# Unpack each downloaded archive next to itself.
foreach ($package in $packages) {
    $target = Join-Path -Path $destination -ChildPath $package.BaseName
    $null = New-Item -Path $target -ItemType Directory -Force
    tar -xjf $package.FullName -C $target
    "Unpacked [$($package.Name)] into [$target]."
}
