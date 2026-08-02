#Requires -Modules @{ ModuleName = 'Pester'; ModuleVersion = '6.0.0'; MaximumVersion = '6.*' }

[Diagnostics.CodeAnalysis.SuppressMessageAttribute(
    'PSUseDeclaredVarsMoreThanAssignments', '',
    Justification = 'Pester assigns shared state in BeforeAll and reads it inside It blocks.'
)]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute(
    'PSAvoidUsingConvertToSecureStringWithPlainText', '',
    Justification = 'The fixed test key never leaves the throwaway test vault.'
)]
[CmdletBinding()]
param()

Describe 'Auth' {
    BeforeAll {
        $script:testVault = . (Join-Path -Path $PSScriptRoot -ChildPath 'Lovdata.TestSetup.ps1')
    }

    AfterAll {
        Remove-ContextVault -Name $script:testVault -Confirm:$false -ErrorAction SilentlyContinue
    }

    AfterEach {
        Get-LovdataContext -ListAvailable | Disconnect-LovdataAccount -Confirm:$false
        Set-LovdataConfig -Name DefaultContext -Value '' -Confirm:$false
    }

    Context 'Connect-LovdataAccount' {
        It 'stores the API key and makes the first connection the default' {
            $context = Connect-LovdataAccount -ApiKey 'test-key' -Context 'first' -PassThru -Confirm:$false

            $context | Should -BeOfType [LovdataContext]
            $context.ID | Should -Be 'first'
            $context.AuthType | Should -Be 'APIKey'
            $context.ApiBaseUri | Should -Be 'https://api.lovdata.no'
            (Get-LovdataConfig).DefaultContext | Should -Be 'first'
        }

        It 'keeps the API key as a secure string' {
            $context = Connect-LovdataAccount -ApiKey 'test-key' -Context 'secure' -PassThru -Confirm:$false

            $context.ApiKey | Should -BeOfType [securestring]
            ($context | Out-String) | Should -Not -Match 'test-key'
        }

        It 'round-trips a secure string key through the store' {
            $secureKey = ConvertTo-SecureString -String 'secure-key' -AsPlainText -Force

            $context = Connect-LovdataAccount -ApiKey $secureKey -Context 'roundtrip' -PassThru -Confirm:$false

            ConvertFrom-SecureString -SecureString $context.ApiKey -AsPlainText | Should -Be 'secure-key'
        }

        It 'leaves an existing default alone unless Default is used' {
            Connect-LovdataAccount -ApiKey 'test-key' -Context 'first' -Confirm:$false
            Connect-LovdataAccount -ApiKey 'test-key' -Context 'second' -Confirm:$false

            (Get-LovdataConfig).DefaultContext | Should -Be 'first'

            Connect-LovdataAccount -ApiKey 'test-key' -Context 'second' -Default -Confirm:$false

            (Get-LovdataConfig).DefaultContext | Should -Be 'second'
        }

        It 'stores the API base URI it was given' {
            $context = Connect-LovdataAccount -ApiKey 'test-key' -Context 'custom' -ApiBaseUri 'https://api.example.test' -PassThru -Confirm:$false

            $context.ApiBaseUri | Should -Be 'https://api.example.test'
        }

        It 'stores nothing when WhatIf is used' {
            Connect-LovdataAccount -ApiKey 'test-key' -Context 'whatif' -WhatIf

            @(Get-LovdataContext -ListAvailable) | Should -HaveCount 0
        }

        It 'refuses the name reserved for the module settings' {
            { Connect-LovdataAccount -ApiKey 'test-key' -Context 'Module' -Confirm:$false } |
                Should -Throw '*reserved for the Lovdata module settings*'
        }

        It 'rejects an empty API key' {
            { Connect-LovdataAccount -ApiKey '  ' -Context 'empty' -Confirm:$false } | Should -Throw
            { Connect-LovdataAccount -ApiKey ([securestring]::new()) -Context 'empty' -Confirm:$false } | Should -Throw
        }
    }

    Context 'Get-LovdataContext' {
        BeforeEach {
            Connect-LovdataAccount -ApiKey 'test-key' -Context 'alpha' -Confirm:$false
            Connect-LovdataAccount -ApiKey 'test-key' -Context 'beta' -Confirm:$false
        }

        It 'returns the default connection when none is named' {
            (Get-LovdataContext).ID | Should -Be 'alpha'
        }

        It 'returns a connection by name' {
            (Get-LovdataContext -Context 'beta').ID | Should -Be 'beta'
        }

        It 'lists every connection without the module settings' {
            $contexts = @(Get-LovdataContext -ListAvailable)

            $contexts.ID | Should -Be @('alpha', 'beta')
            $contexts.ID | Should -Not -Contain 'Module'
        }

        It 'reports a name that was never stored' {
            { Get-LovdataContext -Context 'missing' } | Should -Throw '*was not found*'
        }

        It 'refuses to return the module settings as a connection' {
            { Get-LovdataContext -Context 'Module' } | Should -Throw '*reserved for the Lovdata module settings*'
        }

        It 'asks for a connection when no default is configured' {
            Set-LovdataConfig -Name DefaultContext -Value '' -Confirm:$false

            { Get-LovdataContext } | Should -Throw '*No default Lovdata context is configured*'
        }
    }

    Context 'Switch-LovdataContext' {
        BeforeEach {
            Connect-LovdataAccount -ApiKey 'test-key' -Context 'alpha' -Confirm:$false
            Connect-LovdataAccount -ApiKey 'test-key' -Context 'beta' -Confirm:$false
        }

        It 'changes which connection commands use by default' {
            Switch-LovdataContext -Context 'beta' -Confirm:$false

            (Get-LovdataConfig).DefaultContext | Should -Be 'beta'
            (Get-LovdataContext).ID | Should -Be 'beta'
        }

        It 'returns the connection now in use when PassThru is used' {
            $context = Switch-LovdataContext -Context 'beta' -PassThru -Confirm:$false

            $context | Should -BeOfType [LovdataContext]
            $context.ID | Should -Be 'beta'
        }

        It 'refuses a connection that was never stored' {
            { Switch-LovdataContext -Context 'missing' -Confirm:$false } | Should -Throw '*was not found*'

            (Get-LovdataConfig).DefaultContext | Should -Be 'alpha'
        }

        It 'changes nothing when WhatIf is used' {
            Switch-LovdataContext -Context 'beta' -WhatIf

            (Get-LovdataConfig).DefaultContext | Should -Be 'alpha'
        }
    }

    Context 'Disconnect-LovdataAccount' {
        BeforeEach {
            Connect-LovdataAccount -ApiKey 'test-key' -Context 'alpha' -Confirm:$false
            Connect-LovdataAccount -ApiKey 'test-key' -Context 'beta' -Confirm:$false
        }

        It 'removes a named connection and leaves the others' {
            Disconnect-LovdataAccount -Context 'beta' -Confirm:$false

            @(Get-LovdataContext -ListAvailable).ID | Should -Be @('alpha')
        }

        It 'removes the default connection and clears the default' {
            Disconnect-LovdataAccount -Confirm:$false

            @(Get-LovdataContext -ListAvailable).ID | Should -Be @('beta')
            (Get-LovdataConfig).DefaultContext | Should -BeNullOrEmpty
        }

        It 'keeps the default when another connection is removed' {
            Disconnect-LovdataAccount -Context 'beta' -Confirm:$false

            (Get-LovdataConfig).DefaultContext | Should -Be 'alpha'
        }

        It 'removes every connection it is piped' {
            Get-LovdataContext -ListAvailable | Disconnect-LovdataAccount -Confirm:$false

            @(Get-LovdataContext -ListAvailable) | Should -HaveCount 0
        }

        It 'removes nothing when WhatIf is used' {
            Disconnect-LovdataAccount -Context 'beta' -WhatIf

            @(Get-LovdataContext -ListAvailable) | Should -HaveCount 2
        }

        It 'refuses to remove the module settings' {
            { Disconnect-LovdataAccount -Context 'Module' -Confirm:$false } |
                Should -Throw '*reserved for the Lovdata module settings*'
        }
    }
}
