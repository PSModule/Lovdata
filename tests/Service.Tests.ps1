#Requires -Modules @{ ModuleName = 'Pester'; ModuleVersion = '6.0.0'; MaximumVersion = '6.*' }

[Diagnostics.CodeAnalysis.SuppressMessageAttribute(
    'PSUseDeclaredVarsMoreThanAssignments', '',
    Justification = 'Pester assigns shared state in BeforeAll and reads it inside It blocks.'
)]
[CmdletBinding()]
param()

Describe 'Service' {
    BeforeEach {
        . (Join-Path -Path $PSScriptRoot -ChildPath 'Lovdata.TestSetup.ps1')
    }

    Context 'Test-LovdataConnection' {
        It 'returns true when the service answers' {
            Mock -ModuleName Lovdata Invoke-LovdataAPI { 'Pong' }

            Test-LovdataConnection | Should -BeTrue
        }

        It 'returns false and warns instead of throwing when the service is unreachable' {
            Mock -ModuleName Lovdata Invoke-LovdataAPI { throw 'connection refused' }

            $result = Test-LovdataConnection -WarningAction SilentlyContinue

            $result | Should -BeFalse
        }
    }

    Context 'Get-LovdataApiVersion' {
        It 'maps the reported version onto a typed object' {
            Mock -ModuleName Lovdata Invoke-LovdataAPI {
                [pscustomobject]@{ name = 'lovdata-api'; timestamp = '2026-07-31-1613'; revision = '3806f92' }
            }

            $version = Get-LovdataApiVersion

            $version | Should -BeOfType [LovdataApiVersion]
            $version.Name | Should -Be 'lovdata-api'
            $version.Timestamp | Should -Be '2026-07-31-1613'
            $version.Revision | Should -Be '3806f92'
            Should -Invoke -ModuleName Lovdata Invoke-LovdataAPI -Times 1 -Exactly -ParameterFilter {
                $Endpoint -eq '/version'
            }
        }
    }
}
