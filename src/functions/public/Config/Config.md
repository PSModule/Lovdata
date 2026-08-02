# Configuration

Module-wide Lovdata settings for the current session, principally the API base URI every command sends
requests to. The settings are held in memory only and are never written to disk, because this module
stores no secret: everything the first release covers works with no account and no `API` key.
