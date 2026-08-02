# Documents

Lovdata publishes the current Norwegian acts and central regulations as free open data. These commands
turn that corpus into PowerShell objects, with no account and no `API` key.

`Find-LovdataDocument` and `Get-LovdataDocument` search and read the bundled metadata index the module
ships, so a lookup works offline and needs no download. `Get-LovdataLegalArea` returns the legal-area
taxonomy derived from that index. Pointing `Get-LovdataDocument` at an archive unpacked with
`Expand-LovdataPublicDataset` returns each document in full fidelity, including its body.

## The bundled index

The module ships a metadata-only index of every openly published document, refreshed daily. The index
carries every metadata field except the table of contents, which mirrors the document body and is
available in full only when a document is parsed from an archive. The index records only metadata, never
the statute text, so a caller never mistakes a shipped excerpt for the current law.

## Licence and attribution

The packages are published under the
[Norwegian Licence for Open Government Data (NLOD) 2.0](https://data.norge.no/nlod/en/2.0). Content
retrieved through these commands remains subject to Lovdata's terms; credit Lovdata as the source when
you redistribute it. This module is not affiliated with or endorsed by Lovdata.
