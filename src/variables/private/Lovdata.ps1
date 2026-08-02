$script:Lovdata = [pscustomobject]@{
    # The module-scoped settings used until the user changes them in this session.
    DefaultConfig = [LovdataConfig]@{
        ApiBaseUri = 'https://api.lovdata.no'
    }

    # The in-memory settings for the current session. Seeded from DefaultConfig on first use.
    Config        = $null
}

# The bundled index, loaded and cached on first use so repeated lookups do not re-read the files.
$script:LovdataIndexCache = $null
