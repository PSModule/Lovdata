# Lovdata

A PowerShell module for working with Norwegian legal data from [Lovdata](https://lovdata.no), the foundation that maintains the
authoritative, continuously updated body of Norwegian law. The module wraps the [Lovdata API](https://api.lovdata.no/swagger/index.html)
so laws (`lover`) and regulations (`forskrifter`) can be listed, inspected, and pulled into scripts as PowerShell objects instead of
scraped HTML.

## Prerequisites

- PowerShell 7 or later on Windows, Linux, or macOS.
- An API key from Lovdata for the authenticated endpoints. Lovdata issues keys to users with the `api` role in their user base;
  contact [api@lovdata.no](mailto:api@lovdata.no) to request one. The key is sent as the `X-API-Key` request header on every call.
- No key is needed for Lovdata's free public datasets, which are published under
  [NLOD 2.0](https://data.norge.no/nlod/no/2.0). See [Lovdata's API information page](https://lovdata.no/info/api) for the background.

The API also rate limits each key. Responses carry `X-RateLimit-Limit`, `X-RateLimit-Remaining`, and `X-RateLimit-Reset` headers, and
the module surfaces the remaining budget on verbose output so long-running scripts can pace themselves.

## Installation

Install the module from the PowerShell Gallery:

```powershell
Install-PSResource -Name Lovdata
Import-Module -Name Lovdata
```

## Capabilities

Store the API key once. It is encrypted at rest by the [Context](https://psmodule.io/Context/) module and reused by every
subsequent command, so scripts never carry the key themselves.

```powershell
Connect-LovdataAccount -ApiKey (Read-Host -Prompt 'Lovdata API key' -AsSecureString)
```

List the legal sources the account can reach, then narrow to the ones of interest:

```powershell
Get-LovdataLegalSource
Get-LovdataLegalSource -ID 'lov*'
```

Keep several keys side by side — one per environment or customer — and switch between them without reconnecting:

```powershell
Connect-LovdataAccount -ApiKey $productionKey -Context 'production'
Get-LovdataContext -ListAvailable
Switch-LovdataContext -Context 'production'
```

Module-wide defaults, such as the API base URI, live in their own context and can be inspected or changed:

```powershell
Get-LovdataConfig
Set-LovdataConfig -Name ApiBaseUri -Value 'https://api.lovdata.no'
```

## Attribution

Lovdata publishes current laws and central regulations as open data under the
[Norwegian Licence for Open Government Data (NLOD) 2.0](https://data.norge.no/nlod/no/2.0). Content retrieved through this module
remains subject to Lovdata's terms; credit Lovdata as the source when redistributing it. This module is not affiliated with or
endorsed by Lovdata.

## Documentation

Documentation is published at [psmodule.io/Lovdata](https://psmodule.io/Lovdata/).

Use PowerShell help and command discovery for module details:

```powershell
Get-Command -Module Lovdata
Get-Help -Name Get-LovdataLegalSource -Examples
```
