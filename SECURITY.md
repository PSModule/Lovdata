# Security Policy

## Supported versions

Only the latest published version of the `Lovdata` module is supported. Fixes are released on the current tip of `main`; older
versions are not patched.

## Reporting a vulnerability

Do not open a public issue for a security problem — that would put other users at risk while the problem is unfixed.

Report it privately in one of these ways:

- [Open a private security advisory](https://github.com/PSModule/Lovdata/security/advisories/new) on this repository.
- Email [psmodule@psmodule.io](mailto:psmodule@psmodule.io).

Include what the problem is, how to reproduce it, and the module version you observed it on. Reports are acknowledged and
triaged as quickly as possible.

## Credentials handled by this module

This release handles no credentials. Everything it covers is Lovdata's open, key-free surface, so the module stores no API key
and no other secret, on disk or in memory. There is nothing for this module to leak.

The authenticated Lovdata surface, and the encrypted credential store it will need, are tracked separately in
[PSModule/Lovdata#15](https://github.com/PSModule/Lovdata/issues/15); this section will be revisited when that lands.

Problems with the Lovdata service itself, rather than with this module, belong with Lovdata's own tech support at
[api@lovdata.no](mailto:api@lovdata.no).
