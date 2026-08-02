# Configuration

Module-wide Lovdata settings: the API base URI new connections use, and the stored context that
commands fall back to when none is given. The settings live in their own context in the
`PSModule.Lovdata` vault, separate from any stored API key, so changing them never touches a
credential.

Per-account credentials are managed with the [Auth](../Auth/Auth.md) commands.
