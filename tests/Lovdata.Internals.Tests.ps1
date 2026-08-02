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

Describe 'Lovdata internals' {
    BeforeEach {
        . (Join-Path -Path $PSScriptRoot -ChildPath 'Lovdata.TestSetup.ps1')
        InModuleScope -ModuleName Lovdata {
            $script:Lovdata.Config = [LovdataConfig]@{ ApiBaseUri = 'https://api.example.test' }
        }
    }

    Context 'Types' {
        It 'exports the module types as type accelerators' {
            [LovdataConfig] | Should -Not -BeNullOrEmpty
            [LovdataPublicDataset] | Should -Not -BeNullOrEmpty
            [LovdataApiVersion] | Should -Not -BeNullOrEmpty
        }

        It 'builds a dataset from an object and ignores fields it does not know' {
            $dataset = [LovdataPublicDataset]::new([pscustomobject]@{
                    FileName    = 'gjeldende-lover.tar.bz2'
                    SizeBytes   = 10
                    Unsupported = 'ignored'
                })

            $dataset.FileName | Should -Be 'gjeldende-lover.tar.bz2'
            $dataset.SizeBytes | Should -Be 10
            "$dataset" | Should -Be 'gjeldende-lover.tar.bz2'
        }
    }

    Context 'Invoke-LovdataAPI' {
        It 'builds the request URI from the configured base URI and deserializes the response' {
            InModuleScope -ModuleName Lovdata {
                Mock Invoke-WebRequest {
                    [pscustomobject]@{
                        StatusCode = 200
                        Content    = '[{"filename":"gjeldende-lover.tar.bz2"}]'
                        Headers    = @{ 'X-RateLimit-Remaining' = @('199') }
                    }
                }

                $result = Invoke-LovdataAPI -Endpoint '/v1/publicData/list'

                $result.filename | Should -Be 'gjeldende-lover.tar.bz2'
                Should -Invoke Invoke-WebRequest -Times 1 -Exactly -ParameterFilter {
                    $Method -eq 'Get' -and
                    $Uri -eq 'https://api.example.test/v1/publicData/list' -and
                    -not $Headers.ContainsKey('X-API-Key')
                }
            }
        }

        It 'builds a sorted, encoded query string and drops empty values' {
            InModuleScope -ModuleName Lovdata {
                Mock Invoke-WebRequest {
                    [pscustomobject]@{ StatusCode = 200; Content = '{}'; Headers = @{} }
                }

                Invoke-LovdataAPI -Endpoint 'v1/search' -Query @{ q = 'lov test'; limit = 10; offset = $null }

                Should -Invoke Invoke-WebRequest -Times 1 -Exactly -ParameterFilter {
                    $Uri -eq 'https://api.example.test/v1/search?limit=10&q=lov%20test'
                }
            }
        }

        It 'returns the body unchanged when the API does not answer with JSON' {
            InModuleScope -ModuleName Lovdata {
                Mock Invoke-WebRequest {
                    [pscustomobject]@{ StatusCode = 200; Content = 'Pong'; Headers = @{} }
                }

                Invoke-LovdataAPI -Endpoint '/ping' | Should -Be 'Pong'
            }
        }

        It 'explains an exhausted rate limit and when it resets' {
            InModuleScope -ModuleName Lovdata {
                Mock Invoke-WebRequest {
                    [pscustomobject]@{
                        StatusCode = 429
                        Content    = ''
                        Headers    = @{ 'X-RateLimit-Reset' = @('1602240594'); 'X-RateLimit-Remaining' = @('0') }
                    }
                }

                { Invoke-LovdataAPI -Endpoint '/v1/search' } |
                    Should -Throw '*rate limit is exhausted*The limit resets at*'
            }
        }

        It 'reports any other failure with the status and the endpoint' {
            InModuleScope -ModuleName Lovdata {
                Mock Invoke-WebRequest {
                    [pscustomobject]@{ StatusCode = 500; Content = ''; Headers = @{} }
                }

                { Invoke-LovdataAPI -Endpoint '/v1/search' } |
                    Should -Throw '*https://api.example.test/v1/search*failed with status*500*'
            }
        }
    }

    Context 'Invoke-LovdataDownload' {
        It 'streams the configured download URI to the given file' {
            InModuleScope -ModuleName Lovdata {
                Mock Invoke-WebRequest {}

                Invoke-LovdataDownload -Endpoint '/v1/publicData/get/gjeldende-lover.tar.bz2' -OutFile 'TestDrive:\out.bz2'

                Should -Invoke Invoke-WebRequest -Times 1 -Exactly -ParameterFilter {
                    $Uri -eq 'https://api.example.test/v1/publicData/get/gjeldende-lover.tar.bz2' -and
                    $OutFile -eq 'TestDrive:\out.bz2'
                }
            }
        }
    }

    Context 'Get-LovdataResponseHeader' {
        It 'reads a header regardless of how it is cased' {
            InModuleScope -ModuleName Lovdata {
                $headers = @{ 'X-RateLimit-Remaining' = @('42') }

                Get-LovdataResponseHeader -Headers $headers -Name 'x-ratelimit-remaining' | Should -Be '42'
            }
        }

        It 'returns nothing for a header the response does not carry' {
            InModuleScope -ModuleName Lovdata {
                Get-LovdataResponseHeader -Headers @{} -Name 'X-RateLimit-Reset' | Should -BeNullOrEmpty
                Get-LovdataResponseHeader -Headers $null -Name 'X-RateLimit-Reset' | Should -BeNullOrEmpty
            }
        }
    }
}
