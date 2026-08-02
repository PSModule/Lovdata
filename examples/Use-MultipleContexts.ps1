<#
    .SYNOPSIS
    Work with several Lovdata API keys side by side.

    .DESCRIPTION
    Stores two named Lovdata contexts, inspects them, switches the default between them, and adjusts
    a module-wide setting. Useful when the same script has to run against more than one Lovdata
    account, for example a test account and a production account.
#>

Import-Module -Name Lovdata

Connect-LovdataAccount -ApiKey (Read-Host -Prompt 'Test API key' -AsSecureString) -Context 'test'
Connect-LovdataAccount -ApiKey (Read-Host -Prompt 'Production API key' -AsSecureString) -Context 'production'

# Inspect what is stored. The API key itself is never returned in clear text.
Get-LovdataContext -ListAvailable

# Commands without an explicit -Context use the default one.
Switch-LovdataContext -Context 'production'
Get-LovdataLegalSource

# A single command can target another context without changing the default.
Get-LovdataLegalSource -Context 'test'

# Module-wide defaults live in their own context.
Get-LovdataConfig
Set-LovdataConfig -Name ApiBaseUri -Value 'https://api.lovdata.no'

Get-LovdataContext -ListAvailable | Disconnect-LovdataAccount
