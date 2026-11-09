# Cove for Roku

A Netflix-style **Emby and Jellyfin** client for Roku, the TV companion to [Cove for macOS](https://github.com/J0n4e/cove).
Written in BrightScript / SceneGraph with the [BrighterScript](https://github.com/rokucommunity/brighterscript) tooling.

> Status: early development. Primary test device: **Roku Streambar 9102** (4K, HDR10/HLG, HEVC Main 10).

## Install a test build on your Roku

1. **Enable developer mode** (once): on the Roku remote press
   **Home ×3, Up ×2, Right, Left, Right, Left, Right**. Accept the agreement, set a password and let the Roku restart.
   It shows its address, e.g. `http://192.168.1.50`.
2. Download `cove-roku.zip` (from a GitHub Actions run or a release).
3. On a computer on the same network open `http://<roku-ip>`, sign in as `rokudev` with your password,
   choose **Upload**, pick the zip and press **Install with zip**. Cove starts right away and stays installed
   as the developer channel until another dev build replaces it.

## Develop

```sh
npm ci
npm run build        # lint (bslint) + compile + package to out/cove-roku.zip
npm run lint         # checks only
ROKU_HOST=192.168.1.50 ROKU_PASSWORD=... npm run deploy   # build and sideload to your Roku
```

Debug console: `telnet <roku-ip> 8085` (BrightScript output and crashes).

## Layout

```
src/manifest              app metadata (version is set by CI from the tag)
src/source/               main.bs (entry point) and shared code
src/components/           SceneGraph components (.xml + .bs)
src/images/               icons, splash, logo
scripts/                  version and deploy helpers
```

## Workflow

Feature branches → PR into `Development` → release PR into `main` → tag `vX.Y.Z` builds the zip and drafts a release.

## License

GPL-3.0, like Cove for macOS.
