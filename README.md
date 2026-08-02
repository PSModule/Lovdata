# Lovdata

A PowerShell module for working with Norwegian legal data from [Lovdata](https://lovdata.no), the foundation that maintains the
authoritative, continuously updated body of Norwegian law.

**No account needed.** This release wraps the open, key-free part of the [Lovdata API](https://api.lovdata.no/swagger/index.html):
the current acts (`lover`) and central regulations (`forskrifter`) published as free open data under
[NLOD 2.0](https://data.norge.no/nlod/no/2.0), plus the service endpoints that report whether the API is up and which build is
deployed. Install the module and pull the full corpus of Norwegian acts in two commands, with nothing to configure and no
credential to obtain.

## Prerequisites

- PowerShell 7 or later on Windows, Linux, or macOS.
- No account, no API key, no configuration.

The API rate limits every caller. Responses carry `X-RateLimit-Limit`, `X-RateLimit-Remaining`, and `X-RateLimit-Reset` headers,
and the module surfaces the remaining budget on verbose output so long-running scripts can pace themselves.

## Installation

Install the module from the PowerShell Gallery:

```powershell
Install-PSResource -Name Lovdata
Import-Module -Name Lovdata
```

## Capabilities

Check that the service is up and see which build is deployed:

```powershell
Test-LovdataConnection
Get-LovdataApiVersion
```

List the free open data packages Lovdata publishes, with the size and last-modified date of each:

```powershell
Get-LovdataPublicDataset
Get-LovdataPublicDataset -FileName 'gjeldende-*'
```

Download the current acts and central regulations to a folder, with progress and without silently overwriting existing files:

```powershell
Get-LovdataPublicDataset -FileName 'gjeldende-*' | Save-LovdataPublicDataset -Path './lovdata'
```

Unpack a downloaded package and read its documents as objects, with the full chapter and paragraph structure, clauses, lists,
footnotes, and change notes:

```powershell
$folder = Expand-LovdataPublicDataset -Path './lovdata/gjeldende-lover.tar.bz2'
Get-LovdataDocument -Path $folder -RefID 'lov/1997-02-28-19'
```

Look documents up offline from the metadata index the module ships, refreshed daily, without downloading anything:

```powershell
Get-LovdataDocument -RefID 'lov/1997-02-28-19'
Find-LovdataDocument -Name 'folketrygd'
Find-LovdataDocument -Ministry 'Justis*' -LegalArea 'Strafferett*'
```

Browse the legal-area taxonomy the documents are filed under:

```powershell
Get-LovdataLegalArea
Get-LovdataLegalArea -ID '09*'
```

Point the module at a different API base URI for the session, for example a test deployment:

```powershell
Get-LovdataConfig
Set-LovdataConfig -Name ApiBaseUri -Value 'https://api.lovdata.no'
```

See the [examples](examples) folder for complete scripts, including downloading and unpacking the full corpus.

## Attribution

Lovdata publishes current laws and central regulations as open data under the
[Norwegian Licence for Open Government Data (NLOD) 2.0](https://data.norge.no/nlod/no/2.0). Content retrieved through this module
remains subject to Lovdata's terms; credit Lovdata as the source when redistributing it. This module is not affiliated with or
endorsed by Lovdata.

## The paid surface

Everything Lovdata offers behind an API key -- search, document retrieval, structured rules, vocabularies, reference resolution --
is not covered by this release. That authenticated surface, together with the credential store it needs, is tracked in
[PSModule/Lovdata#15](https://github.com/PSModule/Lovdata/issues/15).

## Documentation

Documentation is published at [psmodule.io/Lovdata](https://psmodule.io/Lovdata/).

Use PowerShell help and command discovery for module details:

```powershell
Get-Command -Module Lovdata
Get-Help -Name Get-LovdataPublicDataset -Examples
```
