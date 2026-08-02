$script:Lovdata = [pscustomobject]@{
    # The Context vault every Lovdata context is stored in.
    ContextVault  = 'PSModule.Lovdata'

    # The module-scoped settings used until the user changes them.
    DefaultConfig = [LovdataConfig]@{
        ID             = 'Module'
        ApiBaseUri     = 'https://api.lovdata.no'
        DefaultContext = ''
    }

    # The configuration loaded from the vault, cached for the lifetime of the session.
    Config        = $null
}
