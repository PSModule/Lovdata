#Requires -Modules @{ ModuleName = 'Pester'; ModuleVersion = '6.0.0'; MaximumVersion = '6.*' }

[Diagnostics.CodeAnalysis.SuppressMessageAttribute(
    'PSUseDeclaredVarsMoreThanAssignments', '',
    Justification = 'Pester assigns shared state in BeforeAll and reads it inside It blocks.'
)]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute(
    'PSReviewUnusedParameter', '',
    Justification = 'Parameters are read by Pester mock parameter filters.'
)]
[CmdletBinding()]
param()

Describe 'LegalSources' {
    BeforeAll {
        $script:testVault = . (Join-Path -Path $PSScriptRoot -ChildPath 'Lovdata.TestSetup.ps1')
        Connect-LovdataAccount -ApiKey 'test-key' -Context 'test' -Confirm:$false
    }

    AfterAll {
        Get-LovdataContext -ListAvailable | Disconnect-LovdataAccount -Confirm:$false
        Remove-ContextVault -Name $script:testVault -Confirm:$false -ErrorAction SilentlyContinue
    }

    Context 'Get-LovdataLegalSource' {
        BeforeEach {
            Mock -ModuleName Lovdata -CommandName Invoke-LovdataAPI -MockWith {
                @(
                    [pscustomobject]@{ id = 'sf'; description = 'Sentrale forskrifter' }
                    [pscustomobject]@{ id = 'lov'; description = 'Lover' }
                    [pscustomobject]@{ id = 'ltavd1'; description = 'Lovtidend avdeling I' }
                )
            }
        }

        It 'asks the API for the legal source list' {
            Get-LovdataLegalSource

            Should -Invoke -ModuleName Lovdata -CommandName Invoke-LovdataAPI -Times 1 -Exactly -ParameterFilter {
                $Endpoint -eq '/v1/legalSource/list' -and $Method -eq 'Get'
            }
        }

        It 'returns every source as a typed, sorted object' {
            $sources = @(Get-LovdataLegalSource)

            $sources | Should -HaveCount 3
            $sources[0] | Should -BeOfType [LovdataLegalSource]
            $sources.ID | Should -Be @('lov', 'ltavd1', 'sf')
            ($sources | Where-Object ID -EQ 'lov').Description | Should -Be 'Lover'
        }

        It 'filters the sources by identifier with wildcards' {
            @(Get-LovdataLegalSource -ID 'lo*').ID | Should -Be @('lov')
            @(Get-LovdataLegalSource -ID 'l*').ID | Should -Be @('lov', 'ltavd1')
            @(Get-LovdataLegalSource -ID 'sf').ID | Should -Be @('sf')
        }

        It 'returns nothing when no source matches' {
            @(Get-LovdataLegalSource -ID 'nothing-matches-this') | Should -HaveCount 0
        }

        It 'uses the connection it is given' {
            Connect-LovdataAccount -ApiKey 'other-key' -Context 'other' -Confirm:$false

            Get-LovdataLegalSource -Context 'other'

            Should -Invoke -ModuleName Lovdata -CommandName Invoke-LovdataAPI -Times 1 -Exactly -ParameterFilter {
                $Context.ID -eq 'other'
            }

            Disconnect-LovdataAccount -Context 'other' -Confirm:$false
        }

        It 'accepts the field names the API is known to use' {
            Mock -ModuleName Lovdata -CommandName Invoke-LovdataAPI -MockWith {
                @([pscustomobject]@{ base = 'nl'; title = 'Norsk Lovtidend' })
            }

            $source = Get-LovdataLegalSource

            $source.ID | Should -Be 'nl'
            $source.Description | Should -Be 'Norsk Lovtidend'
        }

        It 'returns nothing when the API returns nothing' {
            Mock -ModuleName Lovdata -CommandName Invoke-LovdataAPI -MockWith { $null }

            @(Get-LovdataLegalSource) | Should -HaveCount 0
        }
    }
}
