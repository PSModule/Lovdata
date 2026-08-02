#Requires -Modules @{ ModuleName = 'Pester'; ModuleVersion = '6.0.0'; MaximumVersion = '6.*' }

[Diagnostics.CodeAnalysis.SuppressMessageAttribute(
    'PSUseDeclaredVarsMoreThanAssignments', '',
    Justification = 'Pester assigns shared state in BeforeAll and reads it inside It blocks.'
)]
[CmdletBinding()]
param()

Describe 'Config' {
    BeforeEach {
        . (Join-Path -Path $PSScriptRoot -ChildPath 'Lovdata.TestSetup.ps1')
    }

    Context 'Get-LovdataConfig' {
        It 'creates the settings from the module defaults on first read' {
            $config = Get-LovdataConfig

            $config | Should -BeOfType [LovdataConfig]
            $config.ApiBaseUri | Should -Be 'https://api.lovdata.no'
        }

        It 'returns the same settings on a later read' {
            $first = Get-LovdataConfig
            $first.ApiBaseUri = 'https://api.example.test'

            (Get-LovdataConfig).ApiBaseUri | Should -Be 'https://api.example.test'
        }
    }

    Context 'Set-LovdataConfig' {
        It 'changes the API base URI for the session' {
            Set-LovdataConfig -Name ApiBaseUri -Value 'https://api.example.test' -Confirm:$false

            (Get-LovdataConfig).ApiBaseUri | Should -Be 'https://api.example.test'
        }

        It 'returns the updated settings when PassThru is used' {
            $config = Set-LovdataConfig -Name ApiBaseUri -Value 'https://api.example.test' -PassThru -Confirm:$false

            $config | Should -BeOfType [LovdataConfig]
            $config.ApiBaseUri | Should -Be 'https://api.example.test'
        }

        It 'changes nothing when WhatIf is used' {
            Set-LovdataConfig -Name ApiBaseUri -Value 'https://api.whatif.test' -WhatIf

            (Get-LovdataConfig).ApiBaseUri | Should -Be 'https://api.lovdata.no'
        }

        It 'refuses to clear the API base URI' {
            { Set-LovdataConfig -Name ApiBaseUri -Value '' -Confirm:$false } | Should -Throw '*ApiBaseUri cannot be empty*'
        }

        It 'rejects a setting the module does not have' {
            { Set-LovdataConfig -Name 'NotASetting' -Value 'x' -Confirm:$false } | Should -Throw
        }
    }
}
