# Security policy

## Supported versions

Only the latest release of Cove for Roku gets security fixes.

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
