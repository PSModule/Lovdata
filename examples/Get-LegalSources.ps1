<#
    .SYNOPSIS
    Connect to the Lovdata API and list the available legal sources.

    .DESCRIPTION
    Stores a Lovdata API key in an encrypted context, lists the legal sources the account can reach,
    and narrows the result to Norwegian acts. The stored context is reused by every later command in
    the session, so the key is entered once.
#>

Import-Module -Name Lovdata

# The key is read interactively so it never ends up in the script or the shell history.
Connect-LovdataAccount -ApiKey (Read-Host -Prompt 'Lovdata API key' -AsSecureString)

# Every legal source the account has access to.
Get-LovdataLegalSource

# Only the sources whose identifier starts with 'lov'.
Get-LovdataLegalSource -ID 'lov*'

Disconnect-LovdataAccount
