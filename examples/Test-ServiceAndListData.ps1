<#
    .SYNOPSIS
    Check that the Lovdata API is reachable before running a data job.

    .DESCRIPTION
    Uses the open service endpoints to confirm the Lovdata API is up and to record which build is
    deployed, then lists the available open data packages. All of this works with no account and no
    API key, so it is a safe first step in an unattended script.
#>

Import-Module -Name Lovdata

if (-not (Test-LovdataConnection)) {
    Write-Warning 'The Lovdata API is not reachable right now. Try again later.'
    return
}

$version = Get-LovdataApiVersion
"Connected to Lovdata API [$($version.Name)] build [$($version.Timestamp)]."

# List the open data packages the service currently offers.
Get-LovdataPublicDataset | Format-Table -Property FileName, SizeBytes, LastModified
