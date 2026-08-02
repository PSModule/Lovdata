#Requires -Modules @{ ModuleName = 'Pester'; ModuleVersion = '6.0.0'; MaximumVersion = '6.*' }

[Diagnostics.CodeAnalysis.SuppressMessageAttribute(
    'PSUseDeclaredVarsMoreThanAssignments', '',
    Justification = 'Pester assigns shared state in BeforeAll and reads it inside It blocks.'
)]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute(
    'PSReviewUnusedParameter', '',
    Justification = 'Parameters are read inside InModuleScope blocks.'
)]
[CmdletBinding()]
param()

BeforeAll {
    $script:nlRoot = Join-Path -Path $PSScriptRoot -ChildPath 'fixtures/nl'
    # Provenance of the fixtures (real records from the free open data package, NLOD 2.0):
    $script:proseDate = Join-Path -Path $script:nlRoot -ChildPath 'nl-19660506-000.xml'  # dateInForce prose qualifier
    $script:multiDate = Join-Path -Path $script:nlRoot -ChildPath 'nl-20030829-090.xml'  # dateInForce many dates + prose
    $script:multiArea = Join-Path -Path $script:nlRoot -ChildPath 'nl-20010518-022.xml'  # three legal areas
    $script:nested = Join-Path -Path $script:nlRoot -ChildPath 'nl-16870415-000.xml'     # nested sections
    $script:footnotes = Join-Path -Path $script:nlRoot -ChildPath 'nl-20110415-012.xml'  # footnotes
}

Describe 'Lovdata parsing' {
    Context 'ConvertFrom-LovdataMetadata' {
        It 'reads the identity fields keyed on the class attribute' {
            InModuleScope -ModuleName Lovdata -Parameters @{ path = $script:multiArea } {
                param($path)
                $xml = ConvertTo-LovdataXmlDocument -Text ([System.IO.File]::ReadAllText($path))
                $doc = ConvertFrom-LovdataMetadata -Document $xml

                $doc | Should -BeOfType [LovdataDocument]
                $doc.Title | Should -Be 'Lov om garantistillelse fra Statoil ASA ved emisjon og salg av statens aksjer'
                $doc.TitleShort | Should -Be 'Lov om garanti fra Statoil ASA ved aksjesalg'
                $doc.LegacyID | Should -Be 'LOV-2001-05-18-22'
                $doc.LawID | Should -Be '2001-05-18-22'
                $doc.RefID | Should -Be 'lov/2001-05-18-22'
                $doc.DokID | Should -Be 'NL/lov/2001-05-18-22'
            }
        }

        It 'keeps the ministry as a collection' {
            InModuleScope -ModuleName Lovdata -Parameters @{ path = $script:multiArea } {
                param($path)
                $xml = ConvertTo-LovdataXmlDocument -Text ([System.IO.File]::ReadAllText($path))
                $doc = ConvertFrom-LovdataMetadata -Document $xml

                @($doc.Ministry).Count | Should -Be 1
                $doc.Ministry[0] | Should -Be 'Energidepartementet'
            }
        }

        It 'keeps every legal area with its hierarchical path and identifiers' {
            InModuleScope -ModuleName Lovdata -Parameters @{ path = $script:multiArea } {
                param($path)
                $xml = ConvertTo-LovdataXmlDocument -Text ([System.IO.File]::ReadAllText($path))
                $doc = ConvertFrom-LovdataMetadata -Document $xml

                @($doc.LegalAreas).Count | Should -Be 3
                $doc.LegalAreas[0] | Should -BeOfType [LovdataLegalArea]
                $doc.LegalAreas.ID | Should -Contain '04.04'
                $doc.LegalAreas.ID | Should -Contain '26.01'
                $area = $doc.LegalAreas | Where-Object ID -EQ '04.04'
                $area.Name | Should -Be 'Petroleumsvirksomhet'
                $area.Path | Should -Be 'Energirett > Petroleumsvirksomhet'
                @($area.Segments).Count | Should -Be 2
                $area.Segments[0].ID | Should -Be '04'
            }
        }
    }

    Context 'ConvertFrom-LovdataDateField' {
        It 'keeps the raw text, both dates, and the prose qualifier' {
            InModuleScope -ModuleName Lovdata {
                $info = ConvertFrom-LovdataDateField -Text '1966-05-06 med virkning fra 1963-01-01'

                $info | Should -BeOfType [LovdataDateInfo]
                $info.Raw | Should -Be '1966-05-06 med virkning fra 1963-01-01'
                @($info.Dates).Count | Should -Be 2
                $info.Dates[0] | Should -Be ([datetime]'1966-05-06')
                $info.Dates[1] | Should -Be ([datetime]'1963-01-01')
                $info.Note | Should -Be 'med virkning fra'
            }
        }

        It 'collects every date and collapses the leftover separators in a prose-and-many-dates field' {
            InModuleScope -ModuleName Lovdata {
                $info = ConvertFrom-LovdataDateField -Text 'Kongen bestemmer, 2004-01-01, 2005-05-01, 2007-07-01, 2009-01-01'

                @($info.Dates).Count | Should -Be 4
                $info.Note | Should -Be 'Kongen bestemmer'
            }
        }

        It 'reports no note when the field is only a list of dates' {
            InModuleScope -ModuleName Lovdata {
                $info = ConvertFrom-LovdataDateField -Text '1965-07-01, 1967-04-23'

                @($info.Dates).Count | Should -Be 2
                $info.Note | Should -BeNullOrEmpty
            }
        }

        It 'keeps a trailing prose qualifier next to a single date' {
            InModuleScope -ModuleName Lovdata {
                $info = ConvertFrom-LovdataDateField -Text '1971-01-01, departementet bestemmer'

                @($info.Dates).Count | Should -Be 1
                $info.Note | Should -Be 'departementet bestemmer'
            }
        }

        It 'returns an empty result for an empty field' {
            InModuleScope -ModuleName Lovdata {
                $info = ConvertFrom-LovdataDateField -Text ''

                @($info.Dates).Count | Should -Be 0
                $info.Note | Should -BeNullOrEmpty
            }
        }
    }

    Context 'ConvertFrom-LovdataBody' {
        It 'returns a recursive section tree for a nested document' {
            InModuleScope -ModuleName Lovdata -Parameters @{ path = $script:nested } {
                param($path)
                $xml = ConvertTo-LovdataXmlDocument -Text ([System.IO.File]::ReadAllText($path))
                $body = ConvertFrom-LovdataBody -Document $xml

                @($body.Sections).Count | Should -BeGreaterThan 0
                $body.Sections[0] | Should -BeOfType [LovdataSection]

                $maxDepth = 0
                $walk = {
                    param($sections, $depth)
                    if ($depth -gt $script:probeDepth) { $script:probeDepth = $depth }
                    foreach ($section in $sections) { & $walk $section.Sections ($depth + 1) }
                }
                $script:probeDepth = 0
                & $walk $body.Sections 1
                $script:probeDepth | Should -BeGreaterOrEqual 3
            }
        }

        It 'reads footnotes with their labels' {
            InModuleScope -ModuleName Lovdata -Parameters @{ path = $script:footnotes } {
                param($path)
                $xml = ConvertTo-LovdataXmlDocument -Text ([System.IO.File]::ReadAllText($path))
                $body = ConvertFrom-LovdataBody -Document $xml

                @($body.Footnotes).Count | Should -BeGreaterThan 0
                $body.Footnotes[0] | Should -BeOfType [LovdataFootnote]
                $body.Footnotes[0].Label | Should -Not -BeNullOrEmpty
            }
        }

        It 'keeps a non-numeric clause label as text' {
            InModuleScope -ModuleName Lovdata {
                $clause = [LovdataClause]@{ Number = '1a'; Text = 'x' }
                $clause.Number | Should -Be '1a'
            }
        }
    }

    Context 'Export-LovdataIndex' {
        It 'writes a byte-identical file for the same input' {
            InModuleScope -ModuleName Lovdata -Parameters @{ nlRoot = $script:nlRoot; outRoot = $TestDrive } {
                param($nlRoot, $outRoot)
                $documents = foreach ($file in Get-ChildItem -LiteralPath $nlRoot -Filter '*.xml') {
                    $xml = ConvertTo-LovdataXmlDocument -Text ([System.IO.File]::ReadAllText($file.FullName))
                    $doc = ConvertFrom-LovdataMetadata -Document $xml
                    $doc.Source = 'nl'
                    $doc.SourceFile = $file.Name
                    $doc
                }

                $first = Join-Path -Path $outRoot -ChildPath 'a'
                $second = Join-Path -Path $outRoot -ChildPath 'b'
                $null = New-Item -Path $first -ItemType Directory -Force
                $null = New-Item -Path $second -ItemType Directory -Force

                $null = $documents | Export-LovdataIndex -Path $first
                $null = $documents | Export-LovdataIndex -Path $second

                $left = Get-FileHash -LiteralPath (Join-Path -Path $first -ChildPath 'LovdataIndex.nl.json')
                $right = Get-FileHash -LiteralPath (Join-Path -Path $second -ChildPath 'LovdataIndex.nl.json')
                $left.Hash | Should -Be $right.Hash
            }
        }

        It 'writes metadata only and never the document body' {
            InModuleScope -ModuleName Lovdata -Parameters @{ nlRoot = $script:nlRoot; outRoot = $TestDrive } {
                param($nlRoot, $outRoot)
                $file = Join-Path -Path $nlRoot -ChildPath 'nl-16870415-000.xml'
                $xml = ConvertTo-LovdataXmlDocument -Text ([System.IO.File]::ReadAllText($file))
                $doc = ConvertFrom-LovdataMetadata -Document $xml
                $doc.Source = 'nl'

                $out = Join-Path -Path $outRoot -ChildPath 'metaonly'
                $null = New-Item -Path $out -ItemType Directory -Force
                $null = $doc | Export-LovdataIndex -Path $out

                $index = Get-Content -LiteralPath (Join-Path -Path $out -ChildPath 'LovdataIndex.nl.json') -Raw | ConvertFrom-Json
                $keys = $index.documents[0].PSObject.Properties.Name
                $keys | Should -Not -Contain 'Sections'
                $keys | Should -Not -Contain 'Articles'
                $keys | Should -Not -Contain 'TableOfContents'
            }
        }
    }
}

Describe 'Lovdata commands' {
    BeforeAll {
        InModuleScope -ModuleName Lovdata -Parameters @{ nlRoot = $script:nlRoot } {
            param($nlRoot)
            # Build the typed documents the index loader hands back, so mocks return deserialized objects
            # rather than the wire format.
            $script:testDocs = foreach ($file in Get-ChildItem -LiteralPath $nlRoot -Filter '*.xml') {
                $xml = ConvertTo-LovdataXmlDocument -Text ([System.IO.File]::ReadAllText($file.FullName))
                $doc = ConvertFrom-LovdataMetadata -Document $xml
                $doc.Source = 'nl'
                $doc.SourceFile = $file.Name
                $doc
            }
        }
    }

    Context 'Get-LovdataDocument' {
        It 'reads a record from the bundled index offline' {
            InModuleScope -ModuleName Lovdata {
                Mock Import-LovdataIndexData { $script:testDocs }

                $result = Get-LovdataDocument -RefID 'lov/2001-05-18-22'

                $result | Should -BeOfType [LovdataDocument]
                $result.Title | Should -Be 'Lov om garantistillelse fra Statoil ASA ved emisjon og salg av statens aksjer'
                Should -Invoke Import-LovdataIndexData -Times 1 -Exactly
            }
        }

        It 'parses a document in full fidelity from an extracted archive path' {
            $result = Get-LovdataDocument -Path $script:nlRoot -RefID 'lov/1687-04-15'

            $result | Should -BeOfType [LovdataDocument]
            $result.Source | Should -Be 'nl'
            $result.SourceFile | Should -Be 'nl-16870415-000.xml'
            @($result.Sections).Count | Should -BeGreaterThan 0
        }
    }

    Context 'Find-LovdataDocument' {
        It 'finds a document by a plain word in its title' {
            InModuleScope -ModuleName Lovdata {
                Mock Import-LovdataIndexData { $script:testDocs }

                $result = Find-LovdataDocument -Name 'Statoil'

                $result.RefID | Should -Contain 'lov/2001-05-18-22'
            }
        }

        It 'filters by legal area' {
            InModuleScope -ModuleName Lovdata {
                Mock Import-LovdataIndexData { $script:testDocs }

                $result = Find-LovdataDocument -LegalArea '26.*'

                $result.RefID | Should -Contain 'lov/2001-05-18-22'
            }
        }

        It 'filters by ministry' {
            InModuleScope -ModuleName Lovdata {
                Mock Import-LovdataIndexData { $script:testDocs }

                $result = Find-LovdataDocument -Ministry 'Justis*'

                $result.RefID | Should -Contain 'lov/1687-04-15'
            }
        }
    }

    Context 'Get-LovdataLegalArea' {
        It 'derives the taxonomy including the intermediate parent areas' {
            InModuleScope -ModuleName Lovdata {
                Mock Import-LovdataIndexData { $script:testDocs }

                $areas = Get-LovdataLegalArea

                $areas[0] | Should -BeOfType [LovdataLegalArea]
                $areas.ID | Should -Contain '26'
                $areas.ID | Should -Contain '26.01'
                ($areas | Where-Object ID -EQ '26').Path | Should -Be 'Selskaper, fond og foreninger'
            }
        }

        It 'narrows the taxonomy by identifier' {
            InModuleScope -ModuleName Lovdata {
                Mock Import-LovdataIndexData { $script:testDocs }

                $areas = Get-LovdataLegalArea -ID '26.*'

                $areas.ID | Should -Not -Contain '04.04'
                $areas.ID | Should -Contain '26.01'
            }
        }
    }

    Context 'Expand-LovdataPublicDataset' {
        It 'unpacks a package with tar and returns the destination directory' {
            $source = Join-Path -Path $TestDrive -ChildPath 'package'
            $null = New-Item -Path (Join-Path -Path $source -ChildPath 'nl') -ItemType Directory -Force
            Set-Content -Path (Join-Path -Path $source -ChildPath 'nl/doc.xml') -Value '<html></html>'
            $archive = Join-Path -Path $TestDrive -ChildPath 'sample.tar.bz2'
            & tar -cjf $archive -C $source 'nl'
            $LASTEXITCODE | Should -Be 0

            $destination = Join-Path -Path $TestDrive -ChildPath 'out'
            $result = Expand-LovdataPublicDataset -Path $archive -DestinationPath $destination

            $result | Should -BeOfType [System.IO.DirectoryInfo]
            @(Get-ChildItem -LiteralPath $result.FullName -Recurse -Filter '*.xml').Count | Should -Be 1
        }

        It 'throws when the package does not exist' {
            { Expand-LovdataPublicDataset -Path (Join-Path -Path $TestDrive -ChildPath 'missing.tar.bz2') } |
                Should -Throw '*does not exist*'
        }
    }
}
