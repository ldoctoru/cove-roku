# Cove for Roku

Cove is a free, open-source **Emby and Jellyfin** client for Roku TVs and players: your own media server's
films, shows and libraries on a clean, full-screen TV interface. It is the TV companion to
[Cove for macOS](https://github.com/J0n4e/cove) and follows its layout, with a flat, modern look made for the remote.
Written in BrightScript / SceneGraph with the [BrighterScript](https://github.com/rokucommunity/brighterscript) tooling.
Licence: GPL-3.0.

Cove has no accounts, analytics, ads or tracking. It talks only to the servers you add (see [Privacy and security](#privacy-and-security)).

**Latest release: [v1.5.1](https://github.com/ldoctoru/cove-roku/releases/latest)**

## Features

**Look**
- **Clean, flat design** like Apple TV and Emby: the focused button is solid white with dark text, the others have a faint fill. No glass, glow or zoom effects.
- Neutral white and grey throughout. The resume circle on Continue Watching is green so it's easy to spot, and watched titles get a white check badge.
- Library pages show a faint picture of the focused title in the background, fading softly as you move.

**Servers and sign-in**
- Emby and Jellyfin servers, several at a time. Sign in with user name and password, or with **Quick Connect** on Jellyfin.
- **Finds servers on your home network**, so there's no address to type.
- https is tried first; a plain-http server outside your home network shows "This connection isn't encrypted" before you sign in. A sign-in stays tied to the address it was made on.

**Profiles and kids**
- **Several profiles per server** with **Who's watching?** at launch, each with its own Continue Watching and favorites.
- A **PIN per profile** (only a salted hash is stored) and a **maximum rating per profile** (G, PG, PG-13, R): titles above it are hidden everywhere. A limited profile can't change its own limit or PINs, and unrated episodes follow their series' rating.

**Home**
- **Sidebar or top bar**, each with its own list: switch every page and library on or off and change the order.
- A **banner** that shows Newest, Random Picks, Favorites or titles from your rows, refreshed when Home loads or every 15 / 30 / 60 minutes.
- Rows: Continue Watching, Next Up, Upcoming Episodes, Recently Added, Recently Released, Favorites, a row per library, and **My Media**: your libraries as wide tiles with their own artwork, like Emby. Turn rows on or off, reorder them, or use the server's Home layout.
- A library's Home row, My Media tile, top bar entry and sidebar entry are all set separately.

**Libraries and pages**
- Libraries with sort, order, genre, A-Z and show filters (remembered per library), Collections, Shuffle, page jumps with Rewind / Fast Forward, Favorites in sections, Now Playing, Search in rows, and actor pages.
- **Movie, series and episode pages** in the style of Emby: big background picture, title logo, info line (★ score, critics' score, year or air date, runtime, rating, genres, Ends at), and **Audio** and **Subtitles** choices right on the page.
- Buttons: **Play / Resume**, From Beginning, Trailer, Watched, Favorite and **⋯ More** (Add to Collection, Add to Playlist, Playback Info, Quality / Version, Go to Collection / Series / Season, Refresh Metadata for admins). Play is always focused when a page opens or you come back to it.
- Progress with the time remaining, tagline, description and Director; seasons and episodes, Cast & Crew, More Like This, Extras, collections, media info and chapters, and Hide spoilers.
- **For server admins:** **Items without Poster / Backdrop** on library pages, with Refresh per title or **Refresh All Missing**.

**Playback**
- Direct Play whenever the Roku can, otherwise the server converts; the server is told the real play method. The device profile comes from what the Roku reports (4K, HDR10, HLG, Dolby Vision, HEVC, audio formats).
- Player controls in one block at the bottom: timeline with thumbnails, hold-to-seek and Fast Forward / Rewind runs, previous / next episode, jump buttons, episodes, audio, subtitles, quality, chapters, playback speed, "Ends at" and playback info.
- Subtitles drawn by Cove in your style (or the Roku's caption style), with subtitle delay and always load my language. External subtitle files come first and load in pieces, so they start quickly; subtitles added on the server appear without reopening.
- **Up Next** card during the credits, skip intro / recap / credits per segment (Ask, Skip automatically or Don't show), Are you still watching? (episodes only), sleep timer, Cinema Mode, and search and download subtitles from the player.
- Start quality for home network and internet, maximum audio channels, preferred audio, DTS passthrough, and rewind on resume. A failed play offers **Try Again** and **Play Without Subtitles**.

**Settings**
- Same format as Cove for Mac: tabs across the top (General, Home, Libraries, Subtitles, Playback, Connect, Profiles, Remote, About) and sections with the label on the left and the value on the right.

**Roku integration**
- Instant Resume, Roku Search deep links, and voice and transport controls ("pause", "skip forward 30 seconds", Instant Replay).
- The **Audio Guide** reads Cove's own buttons, cards, settings and player controls.

## Requirements

- **A media server** the Roku can reach: **Emby Server 4.8 or later**, or **Jellyfin 10.8 or later**. Cove uses the Jellyfin 10.9+ routes and falls back to the older ones. Older servers may work but aren't supported.
- **A Roku player or TV** with a current Roku OS. The interface is drawn at 1920×1080 (FHD), and the Roku scales it for 720p TVs. 4K, HDR and Dolby Vision depend on the model and the TV; Cove asks the Roku what it can play.
- Developed and tested on a **Roku Streambar 9102X** (Roku OS 16).

## Install

Cove isn't in the Roku Streaming Store yet. Until it is, install it as a developer app ("sideloading"):

1. **Enable developer mode** (once): on the Roku remote press **Home ×3, Up ×2, Right, Left, Right, Left, Right**.
   Accept the agreement, set a password and let the Roku restart. It shows its address, e.g. `http://192.168.1.50`.
2. Download `cove-roku.zip` and `SHA256SUMS.txt` from the [latest release](https://github.com/ldoctoru/cove-roku/releases/latest)
   and check the zip: `sha256sum -c SHA256SUMS.txt` (macOS: `shasum -a 256 -c SHA256SUMS.txt`).
3. On a computer on the same network, open `http://<roku-ip>`, sign in as `rokudev` with your password, choose **Upload**,
   pick the zip and press **Install with zip**. Cove starts and stays installed until another developer build replaces it.

**First start:** Cove looks for servers on your network, or you choose **Add a server** and type its address
(`192.168.1.20:8096`, `https://media.example.com`). Sign in, or use Quick Connect on Jellyfin. When a server has 2 or more
profiles, **Who's watching?** opens at launch. Add profiles, PINs and rating limits in **Settings → Profiles**.

## Privacy and security

- [Privacy Policy](PRIVACY.md): what Cove stores on the Roku (servers, sign-in tokens, profiles, settings) and what it sends to your server.
- [Security Policy](SECURITY.md): how to report a vulnerability privately, and how to verify a release.
- [Terms of Use](TERMS.md).

## Build from source

You need Node.js 22 (as in CI) and npm.

```sh
npm ci
npm run build        # bslint + BrighterScript compile + package → out/cove-roku.zip, then check-shadowing
npm test             # unit tests on the build output (run npm run build first)
npm run lint         # checks only, no package
ROKU_HOST=192.168.1.50 ROKU_PASSWORD=... npm run deploy   # build and sideload to your Roku
```

Debug console: `telnet <roku-ip> 8085` (Cove's `Cove:` log lines, BrightScript errors and crashes). Sign-in tokens
are hidden from the log.

### Scripts

- **`scripts/check-shadowing.js`** runs after `bsc` as part of `npm run build`. It fails when a namespace function's
  name is used as a value in `build/staging`. BrighterScript emits that when a parameter or local shadows a sibling
  namespace function, and it crashes on the Roku with "Type Mismatch" without any compile error. The check matches
  every `Namespace_fn` not followed by `(`, including inside strings and after code on a line. So it can report a
  false positive but not miss a real one: rename the local.
- **`scripts/set-version.js`**: `node scripts/set-version.js 1.0.1` writes the version into `package.json`,
  `package-lock.json` and `src/manifest` (the version PR). In CI on a tag, `--tag vX.Y.Z RUN` fails unless the tag
  equals the `package.json` version, then stamps `build_version` = patch × 1000 + (run number mod 1000), which stays
  at or below 65535. See [RELEASING.md](RELEASING.md).
- **`scripts/make-ui-assets.py`** draws the UI images in `src/images/ui` (9-patches, masks, gradients, icons).
  Use the pinned Pillow: `python3 -m venv .venv && .venv/bin/pip install -r scripts/requirements.txt`, then
  `.venv/bin/python scripts/make-ui-assets.py` (`npm run assets` with that Python first on PATH). `--check` only compares,
  `--font PATH` and `--out DIR` override the defaults. It draws into a temporary folder, then writes new and changed files
  and deletes the ones it no longer makes, except the hand-made `icon_lock_28.png` and `icon_profile_36.png`. The label
  font is the vendored DejaVu Sans Bold 2.37 (`scripts/fonts`, free licence in `LICENSE-DejaVu.txt`). CI regenerates
  the images and fails if they differ from the committed ones.
- **`scripts/deploy.js`** sideloads `out/cove-roku.zip` to `ROKU_HOST` (`npm run deploy`).

### Tests

`npm test` runs two sets of tests:
- **BrightScript unit tests** (`tests/brs/*.test.brs`) on the compiled output in `build/staging/source`, in the Node
  BrightScript interpreter [`@rokucommunity/brs`](https://github.com/rokucommunity/brs). They cover the pure helpers
  (Ratings, HomeLayout, NavPrefs, Subs, Util, Pins, DetailsHead, MissingArt and more). `tests/brs-mocks.js` adds an
  in-memory `roRegistrySection` and an `roEVPDigest` based on Node's crypto, and gives `roRegex.replaceAll` Roku's `\1`
  back-references. Each `sub test_*()` in a test file runs in order, with the `t_eq` / `t_ok` asserts from
  `tests/brs/assert.brs`. `node tests/run.js util` runs one file.
- **Script tests** (`tests/scripts/*.test.js`, `node --test`) for set-version and check-shadowing.

Screens and Tasks (SceneGraph nodes, network) aren't covered, because they need a Roku.

### Layout

```
src/manifest              app metadata; the version comes from the version PR (scripts/set-version.js), CI adds the build number on tags
src/source/               main.bs (entry point) and the shared namespaces (Api, Items, Playback, Subs, Ratings, Pins, Servers, Prefs, ...)
src/components/           SceneGraph components (.xml + .bs): MainScene, home, details, library, player, settings, tasks, ...
src/images/               icons, splash, logo; ui/ is generated by scripts/make-ui-assets.py
scripts/                  build, version, asset and deploy helpers (see Scripts)
tests/                    unit tests (npm test)
.github/workflows/        CI: build, tests, Roku Static Channel Analysis, UI assets check, releases
```

## Contributing

- `Development` is the default branch and it is protected. Open a pull request into `Development` from a feature
  branch. The `build` check (bslint, compile, unit tests, Roku Static Channel Analysis) must pass.
- Run `npm run build && npm test` before pushing. Follow bslint's style, and don't name a parameter or local like a
  namespace (`items` next to `Items`) or like a namespace function.
- Releases go `Development` → `main` → a `vX.Y.Z` tag: see [RELEASING.md](RELEASING.md).
- Report security problems privately (see [SECURITY.md](SECURITY.md)), not in a public issue.

## Credits

- Original project: [J0n4e/cove](https://github.com/J0n4e/cove), an Emby media player for macOS. Cove for Roku follows its
  design and server logic; no Swift code is used.
- DejaVu fonts (used only at build time, for generated icons): see `scripts/fonts/LICENSE-DejaVu.txt`.

## License

GPL-3.0, the same licence as the original Cove project. See [LICENSE](LICENSE).
