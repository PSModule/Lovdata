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

Describe 'PublicData' {
    BeforeEach {
        . (Join-Path -Path $PSScriptRoot -ChildPath 'Lovdata.TestSetup.ps1')
    }

    Context 'Get-LovdataPublicDataset' {
        It 'returns the packages as typed objects with no API key stored' {
            Mock -ModuleName Lovdata Invoke-LovdataAPI {
                @(
                    [pscustomobject]@{
                        filename     = 'gjeldende-lover.tar.bz2'
                        description  = 'Gjeldende lover, ajourfort med endringer'
                        sizeBytes    = '5842472'
                        lastModified = '2026-08-01T01:31:00Z'
                    }
                )
            }

            $result = Get-LovdataPublicDataset

            $result | Should -BeOfType [LovdataPublicDataset]
            $result.FileName | Should -Be 'gjeldende-lover.tar.bz2'
            $result.SizeBytes | Should -Be 5842472
            $result.SizeBytes | Should -BeOfType [long]
            $result.LastModified | Should -BeOfType [datetime]
            Should -Invoke -ModuleName Lovdata Invoke-LovdataAPI -Times 1 -Exactly -ParameterFilter {
                $Endpoint -eq '/v1/publicData/list'
            }
        }

        It 'filters the packages by filename wildcard' {
            Mock -ModuleName Lovdata Invoke-LovdataAPI {
                $modified = '2026-08-01T01:31:00Z'
                @(
                    [pscustomobject]@{ filename = 'gjeldende-lover.tar.bz2'; sizeBytes = '1'; lastModified = $modified }
                    [pscustomobject]@{ filename = 'gjeldende-sentrale-forskrifter.tar.bz2'; sizeBytes = '2'; lastModified = $modified }
                    [pscustomobject]@{ filename = 'historiske-lover.tar.bz2'; sizeBytes = '3'; lastModified = $modified }
                )
            }

            $result = Get-LovdataPublicDataset -FileName 'gjeldende-*'

            $result.FileName | Should -Be @('gjeldende-lover.tar.bz2', 'gjeldende-sentrale-forskrifter.tar.bz2')
        }
    }

    Context 'Save-LovdataPublicDataset' {
        BeforeEach {
            $script:downloadDir = Join-Path -Path $TestDrive -ChildPath ([guid]::NewGuid().Guid)
            $null = New-Item -Path $script:downloadDir -ItemType Directory
        }

        It 'downloads a package into the target directory and returns the file' {
            Mock -ModuleName Lovdata Invoke-LovdataDownload {
                Set-Content -Path $OutFile -Value 'data'
            }

            $result = Save-LovdataPublicDataset -FileName 'gjeldende-lover.tar.bz2' -Path $script:downloadDir

            $result | Should -BeOfType [System.IO.FileInfo]
            $result.Name | Should -Be 'gjeldende-lover.tar.bz2'
            Should -Invoke -ModuleName Lovdata Invoke-LovdataDownload -Times 1 -Exactly -ParameterFilter {
                $Endpoint -eq '/v1/publicData/get/gjeldende-lover.tar.bz2' -and
                $OutFile -eq (Join-Path -Path $script:downloadDir -ChildPath 'gjeldende-lover.tar.bz2')
            }
        }

        It 'refuses to overwrite an existing file without Force' {
            Mock -ModuleName Lovdata Invoke-LovdataDownload {}
            $existing = Join-Path -Path $script:downloadDir -ChildPath 'gjeldende-lover.tar.bz2'
            Set-Content -Path $existing -Value 'old'

            { Save-LovdataPublicDataset -FileName 'gjeldende-lover.tar.bz2' -Path $script:downloadDir } |
                Should -Throw '*already exists*'
            Should -Invoke -ModuleName Lovdata Invoke-LovdataDownload -Times 0 -Exactly
        }

        It 'overwrites an existing file when Force is given' {
            Mock -ModuleName Lovdata Invoke-LovdataDownload {
                Set-Content -Path $OutFile -Value 'new'
            }
            $existing = Join-Path -Path $script:downloadDir -ChildPath 'gjeldende-lover.tar.bz2'
            Set-Content -Path $existing -Value 'old'

            Save-LovdataPublicDataset -FileName 'gjeldende-lover.tar.bz2' -Path $script:downloadDir -Force
            Should -Invoke -ModuleName Lovdata Invoke-LovdataDownload -Times 1 -Exactly
        }

        It 'downloads nothing when WhatIf is used' {
            Mock -ModuleName Lovdata Invoke-LovdataDownload {}

            Save-LovdataPublicDataset -FileName 'gjeldende-lover.tar.bz2' -Path $script:downloadDir -WhatIf
            Should -Invoke -ModuleName Lovdata Invoke-LovdataDownload -Times 0 -Exactly
        }

        It 'accepts a dataset from the pipeline by property name' {
            Mock -ModuleName Lovdata Invoke-LovdataDownload {
                Set-Content -Path $OutFile -Value 'data'
            }
            $dataset = [LovdataPublicDataset]@{ FileName = 'gjeldende-lover.tar.bz2' }

            $result = $dataset | Save-LovdataPublicDataset -Path $script:downloadDir

            $result.Name | Should -Be 'gjeldende-lover.tar.bz2'
            Should -Invoke -ModuleName Lovdata Invoke-LovdataDownload -Times 1 -Exactly
        }
    }
}
