# Authentication

Lovdata authenticates with an API key sent in the `X-API-Key` header. Keys are issued by Lovdata to
users holding the `api` role — contact [api@lovdata.no](mailto:api@lovdata.no) to request one.

`Connect-LovdataAccount` stores a key in an encrypted context in the `PSModule.Lovdata` vault, handled
by the [Context](https://psmodule.io/Context/) module. Every other command reads the key from there, so
a key is entered once and never appears in a script.

Several keys can be stored side by side under different names — one per account or environment. One of
them is the default: `Connect-LovdataAccount` makes the first stored context the default, and
`Switch-LovdataContext` moves it. Any single command can still target another connection through its own
`-Context` parameter. `Get-LovdataContext` shows what is stored and `Disconnect-LovdataAccount` removes it.

Removing a context deletes the local copy of the key; it does not revoke the key with Lovdata. Revoke a
leaked key with Lovdata as well.

Settings that are not tied to a single key are managed with the [Config](../Config/Config.md) commands.
