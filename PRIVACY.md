# Cove for Roku: Privacy Policy

*Effective: November 12, 2026*

Cove for Roku ("Cove") is a free, open-source app for playing videos from **your own Emby or Jellyfin media server** on a Roku device. This policy explains what information Cove handles and where it goes.

## In short

- Cove has **no accounts, no analytics, no advertising and no tracking**.
- Cove talks **only to the media servers you add**. The Cove developers run no servers and receive **no information** from the app.
- What Cove stores stays **on your Roku device**.

## Information stored on your Roku device

Cove keeps the following in the Roku's app storage (the "registry"), only on your device:

- the media servers you added: their name, address, type (Emby or Jellyfin) and version;
- for each server: the user name you signed in with, your user ID and the **access token** the server issued (your **password is not stored**);
- your Cove settings (colours, layout, libraries, subtitle and playback preferences) and the subtitle language chosen for each series.

You can remove a server, or sign out, in **Settings → Servers**. **Settings → About → Reset All Settings** clears the settings. Removing Cove from your Roku deletes all of this.

## Information sent to your media server

To show your libraries and play videos, Cove sends requests to the server you added, and only to that server. These requests include:

- your user name and password **when you sign in** (sent once to obtain the access token), or a Quick Connect code on Jellyfin;
- the access token, an app name ("Cove"), the app version, the Roku's name (as set in the Roku's settings; when the Roku has no name, its model name, for example "Roku Streambar") and a device identifier that Roku provides **for this app only** (it is different for every app and cannot be used to identify you across apps);
- what you browse, search for, play, mark as watched or add to favourites, your playback position and playback settings (so the server can resume, convert and report playback, as with any Emby or Jellyfin app);
- the Roku's video capabilities (for example 4K, HDR or the supported formats), so the server can choose a stream that plays.

How your server stores and uses this information is decided by **whoever runs that server** (usually you, or the person who gave you access) and by the Emby or Jellyfin software. Please see [Emby's privacy policy](https://emby.media/privacy.html). Jellyfin has no separate privacy policy for self-hosted servers: see [jellyfin.org](https://jellyfin.org/).

If your server address starts with `https://`, the connection is encrypted and the server's certificate is checked. With `http://` (common on home networks) it is not encrypted.

When you type a server address without `https://` or `http://`, Cove tries `https://` first and uses plain `http://` only if the server doesn't answer over https. A server on plain http is marked "Not encrypted" in the server list and in **Settings → Servers**. If such a server is not on your home network, Cove warns you ("This connection isn't encrypted") before you sign in, because your password and sign-in could then be read on the networks in between.

Cove sends the access token only to the address it was issued for: if the same server is added again under a different address, you sign in again there. Signing out or removing a server also ends the session on the server when it can be reached.

## Roku

Roku itself may collect information about your use of the device and its apps under **Roku's own privacy policy** (<https://docs.roku.com/published/userprivacypolicy/en/us>). Cove does not receive any of it.

## Children

Cove does not collect personal information from anyone, including children. What can be watched depends entirely on the content of your own media server and its parental controls.

## Changes

If this policy changes, the new version will be published at this address with a new effective date.

## Contact

Questions or concerns: open an issue at <https://github.com/ldoctoru/cove-roku/issues>.
