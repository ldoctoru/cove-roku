# Cove for Roku: Privacy Policy

*Effective: November 15, 2026*

Cove for Roku ("Cove") is a free, open-source app for playing videos from **your own Emby or Jellyfin media server** on a Roku device. This policy explains what information Cove handles and where it goes.

## In short

- Cove has **no accounts, no analytics, no advertising and no tracking**.
- Cove talks **only to the media servers you add**. The Cove developers run no servers and receive **no information** from the app.
- What Cove stores stays **on your Roku device**.

## Information stored on your Roku device

Cove keeps the following in the Roku's app storage (the "registry"), only on your device:

- the media servers you added: their name, address, type (Emby or Jellyfin) and version;
- for each server, its **profiles** (each user who signed in on this Roku): the user name, user ID, the **access token** the server issued (your **password is not stored**) and the image tag of the user's picture;
- for each profile, if set: a **salted hash of its 4-digit PIN** (the PIN itself is not stored), its **rating limit** and whether it hides unrated titles; and, per server, whether Cove asks "Who's watching?" at start;
- counters of **wrong PIN entries** and the time until a PIN can be tried again;
- your Cove settings (colours, layout, libraries, subtitle and playback preferences), the order and visibility of the Home rows for each server, the sort and filters you last used in each library, and the subtitle language chosen for each series.

You can remove a server, or sign out, in **Settings → Servers**, and sign out a profile in **Settings → Profiles**. **Settings → About → Reset All Settings** puts the settings back to their defaults; it keeps your servers, profiles, PINs, rating limits and the wrong-PIN counters. Removing Cove from your Roku deletes all of this.

A PIN hash is not strong protection: a 4-digit PIN has only 10 000 possible values, so someone able to read the app's storage could find it by trying them all. The PIN is a household lock, not a password.

## Information sent to your media server

To show your libraries and play videos, Cove sends requests to the server you added, and only to that server. These requests include:

- your user name and password **when you sign in** (sent once to obtain the access token), or a Quick Connect code on Jellyfin;
- the access token, an app name ("Cove"), the app version, the Roku's name (as set in the Roku's settings; when the Roku has no name, its model name, for example "Roku Streambar") and a device identifier that Roku provides **for this app only** (it is different for every app and cannot be used to identify you across apps);
- what you browse, search for, play, mark as watched or add to favourites, your playback position and playback settings (so the server can resume, convert and report playback, as with any Emby or Jellyfin app);
- the Roku's video capabilities (for example 4K, HDR or the supported formats), so the server can choose a stream that plays.

How your server stores and uses this information is decided by **whoever runs that server** (usually you, or the person who gave you access) and by the Emby or Jellyfin software. Please see [Emby's privacy policy](https://emby.media/privacy.html). Jellyfin has no separate privacy policy for self-hosted servers: see [jellyfin.org](https://jellyfin.org/).

If your server address starts with `https://`, the connection is encrypted and the server's certificate is checked. With `http://` (common on home networks) it is not encrypted.

When you type a server address without `https://` or `http://`, Cove tries `https://` first and uses plain `http://` only if the server doesn't answer over https. A server on plain http is marked "Not encrypted" in the server list and in **Settings → Servers**. If such a server is not on your home network, Cove warns you ("This connection isn't encrypted") before you sign in, because your password and sign-in could then be read on the networks in between.

Cove sends the access token in its own requests only to the address it was issued for: if the same server is added again under a different address, you sign in again there. Two limits apply: the token is also part of some stream and image addresses Cove gives the Roku's player (as `api_key=`), so it can appear in your server's or reverse proxy's access logs; and if your server answers a request with a redirect to another address, the Roku follows it and Cove doesn't filter where it goes. Signing out or removing a server also ends the session on the server when it can be reached.

## Roku

Roku itself may collect information about your use of the device and its apps under **Roku's own privacy policy** (<https://docs.roku.com/published/userprivacypolicy/en/us>). Cove does not receive any of it.

## Children

Cove does not collect personal information from anyone, including children.

What can be watched depends on the content of your own media server and on two kinds of limits:

- **Your server's parental controls** (per user, in the Emby or Jellyfin dashboard: maximum rating, blocked tags, blocking unrated items). These are enforced by the server and are the stronger protection.
- **Cove's rating limit** per profile (**Settings → Profiles**): titles rated above the limit are hidden in Cove. An episode without its own rating takes its series' rating. Other titles without a rating, or with a rating Cove doesn't recognize, stay visible unless the profile has **Hide unrated titles** on. A rating limit can only be changed with a parent PIN (the PIN of a profile without a limit), and while a profile with a limit is in use, changing profiles, PINs, servers or resetting the settings also asks for it.

Cove's limit is a convenience on this Roku, not a replacement for the server's parental controls: give a child their own server user with the server's limits set.

## Changes

If this policy changes, the new version will be published at this address with a new effective date.

## Contact

Questions or concerns: open an issue at <https://github.com/ldoctoru/cove-roku/issues>.
