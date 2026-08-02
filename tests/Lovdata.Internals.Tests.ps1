#Requires -Modules @{ ModuleName = 'Pester'; ModuleVersion = '6.0.0'; MaximumVersion = '6.*' }

[Diagnostics.CodeAnalysis.SuppressMessageAttribute(
    'PSUseDeclaredVarsMoreThanAssignments', '',
    Justification = 'Pester assigns shared state in BeforeAll and reads it inside It blocks.'
)]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute(
    'PSReviewUnusedParameter', '',
    Justification = 'Parameters are read by Pester mock parameter filters.'
)]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute(
    'PSAvoidUsingConvertToSecureStringWithPlainText', '',
    Justification = 'The fixed test key never leaves the mocked request boundary.'
)]
[CmdletBinding()]
param()

Describe 'Lovdata internals' {
    BeforeAll {
        $script:testVault = . (Join-Path -Path $PSScriptRoot -ChildPath 'Lovdata.TestSetup.ps1')
    }

    AfterAll {
        Remove-ContextVault -Name $script:testVault -Confirm:$false -ErrorAction SilentlyContinue
    }

    Context 'Types' {
        It 'exports the module types as type accelerators' {
            [LovdataConfig] | Should -Not -BeNullOrEmpty
            [LovdataContext] | Should -Not -BeNullOrEmpty
            [LovdataLegalSource] | Should -Not -BeNullOrEmpty
        }

        It 'builds a context from an object and ignores fields it does not know' {
            $context = [LovdataContext]::new([pscustomobject]@{
                    ID          = 'demo'
                    ApiBaseUri  = 'https://api.example.test'
                    AuthType    = 'APIKey'
                    Unsupported = 'ignored'
                })

            $context.ID | Should -Be 'demo'
            $context.ApiBaseUri | Should -Be 'https://api.example.test'
            "$context" | Should -Be 'demo'
        }
    }

    Context 'Invoke-LovdataAPI' {
        It 'sends the API key as the X-API-Key header and deserializes the response' {
            InModuleScope -ModuleName Lovdata {
                Mock Invoke-WebRequest {
                    [pscustomobject]@{
                        StatusCode = 200
                        Content    = '[{"id":"lov","description":"Lover"}]'
                        Headers    = @{ 'X-RateLimit-Remaining' = @('199') }
                    }
                }

                $context = [LovdataContext]@{
                    ID         = 'demo'
                    ApiBaseUri = 'https://api.example.test'
                    AuthType   = 'APIKey'
                    ApiKey     = ConvertTo-SecureString -String 'secret-key' -AsPlainText -Force
                }

                $result = Invoke-LovdataAPI -Endpoint '/v1/legalSource/list' -Context $context

                $result.id | Should -Be 'lov'
                Should -Invoke Invoke-WebRequest -Times 1 -Exactly -ParameterFilter {
                    $Method -eq 'Get' -and
                    $Uri -eq 'https://api.example.test/v1/legalSource/list' -and
                    $Headers['X-API-Key'] -eq 'secret-key'
                }
            }
        }

        It 'builds a sorted, encoded query string and drops empty values' {
            InModuleScope -ModuleName Lovdata {
                Mock Invoke-WebRequest {
                    [pscustomobject]@{ StatusCode = 200; Content = '{}'; Headers = @{} }
                }

                $context = [LovdataContext]@{
                    ID         = 'demo'
                    ApiBaseUri = 'https://api.example.test/'
                    ApiKey     = ConvertTo-SecureString -String 'secret-key' -AsPlainText -Force
                }

                Invoke-LovdataAPI -Endpoint 'v1/search' -Query @{ q = 'lov test'; limit = 10; offset = $null } -Context $context

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

                $context = [LovdataContext]@{
                    ID         = 'demo'
                    ApiBaseUri = 'https://api.example.test'
                    ApiKey     = ConvertTo-SecureString -String 'secret-key' -AsPlainText -Force
                }

                Invoke-LovdataAPI -Endpoint '/ping' -Context $context | Should -Be 'Pong'
            }
        }

        It 'explains a rejected API key' {
            InModuleScope -ModuleName Lovdata {
                Mock Invoke-WebRequest {
                    [pscustomobject]@{
                        StatusCode = 401
                        Content    = '{"status":401,"message":"Unauthorized","detail":"Missing api role"}'
                        Headers    = @{}
                    }
                }

                $context = [LovdataContext]@{
                    ID         = 'demo'
                    ApiBaseUri = 'https://api.example.test'
                    ApiKey     = ConvertTo-SecureString -String 'secret-key' -AsPlainText -Force
                }

                { Invoke-LovdataAPI -Endpoint '/v1/legalSource/list' -Context $context } |
                    Should -Throw '*rejected the API key in context*demo*Missing api role*'
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

                $context = [LovdataContext]@{
                    ID         = 'demo'
                    ApiBaseUri = 'https://api.example.test'
                    ApiKey     = ConvertTo-SecureString -String 'secret-key' -AsPlainText -Force
                }

                { Invoke-LovdataAPI -Endpoint '/v1/search' -Context $context } |
                    Should -Throw '*rate limit for context*demo*is exhausted*The limit resets at*'
            }
        }

        It 'reports any other failure with the status and the endpoint' {
            InModuleScope -ModuleName Lovdata {
                Mock Invoke-WebRequest {
                    [pscustomobject]@{ StatusCode = 500; Content = ''; Headers = @{} }
                }

                $context = [LovdataContext]@{
                    ID         = 'demo'
                    ApiBaseUri = 'https://api.example.test'
                    ApiKey     = ConvertTo-SecureString -String 'secret-key' -AsPlainText -Force
                }

                { Invoke-LovdataAPI -Endpoint '/v1/search' -Context $context } |
                    Should -Throw '*https://api.example.test/v1/search*failed with status*500*'
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

    Context 'Resolve-LovdataContext' {
        BeforeEach {
            Connect-LovdataAccount -ApiKey 'test-key' -Context 'alpha' -Confirm:$false
            Connect-LovdataAccount -ApiKey 'test-key' -Context 'beta' -Confirm:$false
        }

        AfterEach {
            Get-LovdataContext -ListAvailable | Disconnect-LovdataAccount -Confirm:$false
            Set-LovdataConfig -Name DefaultContext -Value '' -Confirm:$false
        }

        It 'falls back to the default connection' {
            InModuleScope -ModuleName Lovdata {
                (Resolve-LovdataContext -Context $null).ID | Should -Be 'alpha'
                (Resolve-LovdataContext -Context '').ID | Should -Be 'alpha'
            }
        }

        It 'resolves a connection by name' {
            InModuleScope -ModuleName Lovdata {
                (Resolve-LovdataContext -Context 'beta').ID | Should -Be 'beta'
            }
        }

        It 'passes an already resolved connection straight through' {
            InModuleScope -ModuleName Lovdata {
                $context = Get-LovdataContext -Context 'beta'

                (Resolve-LovdataContext -Context $context).ID | Should -Be 'beta'
            }
        }

        It 'asks for a key when the connection has none' {
            InModuleScope -ModuleName Lovdata {
                $context = [LovdataContext]@{ ID = 'keyless'; ApiBaseUri = 'https://api.example.test' }

                { Resolve-LovdataContext -Context $context } | Should -Throw '*has no API key*'
            }
        }

        It 'asks for a base URI when the connection has none' {
            InModuleScope -ModuleName Lovdata {
                $context = [LovdataContext]@{
                    ID     = 'uriless'
                    ApiKey = ConvertTo-SecureString -String 'secret-key' -AsPlainText -Force
                }

                { Resolve-LovdataContext -Context $context } | Should -Throw '*has no API base URI*'
            }
        }
    }

    Context 'Initialize-LovdataConfig' {
        It 'backfills settings that a stored configuration predates' {
            InModuleScope -ModuleName Lovdata {
                $null = Set-Context -ID 'Module' -Context ([pscustomobject]@{ ID = 'Module' }) -Vault $script:Lovdata.ContextVault

                Initialize-LovdataConfig -Force

                $script:Lovdata.Config.ApiBaseUri | Should -Be 'https://api.lovdata.no'
                (Get-Context -ID 'Module' -Vault $script:Lovdata.ContextVault).ApiBaseUri | Should -Be 'https://api.lovdata.no'
            }
        }
    }
}
