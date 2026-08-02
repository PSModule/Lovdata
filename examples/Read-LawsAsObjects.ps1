<#
    .SYNOPSIS
    Read Norwegian acts as objects, both offline from the bundled index and in full from an archive.

    .DESCRIPTION
    Shows the two ways to read documents. Find-LovdataDocument and Get-LovdataDocument read the metadata
    index the module ships, so a lookup needs no network access and no download. Pointing
    Get-LovdataDocument at an archive unpacked with Expand-LovdataPublicDataset returns each document in
    full, including its chapter and paragraph structure. Get-LovdataLegalArea returns the taxonomy the
    documents are filed under. No account and no API key are needed. The content is published under
    NLOD 2.0; credit Lovdata as the source when you redistribute it.
#>

Import-Module -Name Lovdata

# Search the bundled index offline, by title, identifier, ministry, or legal area.
Find-LovdataDocument -Name 'folketrygd' |
    Format-Table -Property RefID, TitleShort, @{ Name = 'Ministry'; Expression = { $_.Ministry -join ', ' } }

# Read a single record's metadata from the bundled index, still offline.
$record = Get-LovdataDocument -RefID 'lov/1997-02-28-19'
"$($record.Title) is in force from $($record.DateInForce.Raw)."

# Browse the legal-area taxonomy the documents are filed under.
Get-LovdataLegalArea -ID '33*' | Format-Table -Property ID, Path

# For the full text and structure, unpack a downloaded package and parse it.
$destination = Join-Path -Path (Get-Location) -ChildPath 'lovdata'
$null = New-Item -Path $destination -ItemType Directory -Force
$archive = Get-LovdataPublicDataset -FileName 'gjeldende-lover.tar.bz2' |
    Save-LovdataPublicDataset -Path $destination -Force
$folder = Expand-LovdataPublicDataset -Path $archive.FullName -Force

# The archive form carries the recursive section and article structure the index leaves out.
$document = Get-LovdataDocument -Path $folder -RefID 'lov/1997-02-28-19'
"$($document.Title) has $($document.Sections.Count) top-level chapters."
