# Security policy

## Supported versions

Only the latest release of Cove for Roku gets security fixes.

## Threat model

Cove trusts the media servers you add: their answers, the stream addresses they return and the redirects they
send are followed as given. Access tokens are kept in the Roku's app storage and sent only to the server's own
address in Cove's requests, but they also ride in stream URLs (`api_key=`), and redirects aren't filtered.
Since v1.6 the token of a request goes in the `Authorization` header for Emby too (as for Jellyfin), which the
Roku drops when a redirect leads to another host; an Emby server that refuses that form and accepts the old
`X-Emby-Token` header is remembered and keeps the old form, which a redirect still carries along.
Plain `http://` is allowed (it is common on home networks); Cove marks such servers "Not encrypted" and warns
before you sign in to one outside your home network. Profile PINs and Cove's rating limits are a household lock
for people using the same Roku, not access control: they are checked only on this Roku, a 4-digit PIN can be
found from its stored hash by anyone able to read the app's storage, and the server's own parental controls are
what really limits a user. Reports that break these assumptions in a way that matters (a token sent to another
host, a limit bypass from the remote, a crash from a server answer) are welcome.

## Reporting a vulnerability

Please report security problems privately, not in a public issue: use
[Report a vulnerability](https://github.com/ldoctoru/cove-roku/security/advisories/new) on GitHub
(Security → Advisories). Include the Cove version, the Roku model and OS version, the server type
(Emby / Jellyfin) and the steps to reproduce.

You should get an answer within a week. Please give us a reasonable time to release a fix before
publishing details.

## Verifying a release

Each GitHub release has a `SHA256SUMS.txt` next to `cove-roku.zip`. Check the download with
`sha256sum -c SHA256SUMS.txt` (macOS: `shasum -a 256 -c SHA256SUMS.txt`) before sideloading it.
