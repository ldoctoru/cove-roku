# Releasing Cove for Roku

Roku versions are `major.minor.build`. Cove uses semver tags `vX.Y.Z`: `src/manifest` gets X and Y, and the patch
goes into `build_version` (see `scripts/set-version.js`). `main` and `Development` are protected (changes only
through PRs with a passing `build` check), and a tag ruleset lets only the Admin role create, move or delete `v*` tags.

Only release code that has already been tested on a Roku from the PR's CI zip.

## 1. Version PR into Development

```sh
git checkout -b chore/vX.Y.Z origin/Development
node scripts/set-version.js X.Y.Z      # package.json, package-lock.json, src/manifest (build = patch * 1000)
npm run build && npm test
git commit -am "Version X.Y.Z" && git push -u origin chore/vX.Y.Z
gh pr create --base Development --title "Version X.Y.Z" --body "Version bump for vX.Y.Z"
```

Merge it once the `build` check passes. Without this step, sideloaded builds of Development keep showing the old
version, and the tag build in step 3 fails on purpose.

## 2. Release PR: Development → main

```sh
gh pr create --base main --head Development --title "Release vX.Y.Z" --body-file notes.md
gh pr checks <number> --watch
gh pr merge <number> --merge           # a merge commit; keep Development
```

`notes.md` holds the release notes: what's new per screen, Fixes, and Install (developer mode). The same file is used
in step 5.

## 3. Tag (admin only)

```sh
git fetch origin
git tag -a vX.Y.Z origin/main -m "Cove for Roku vX.Y.Z"
git push origin vX.Y.Z
```

The push prints "Bypassed rule violations" for an admin under the tag ruleset; that's expected.

The tag run (`.github/workflows/build.yml`):
- `set-version.js --tag` **fails the build if the tag isn't the `package.json` version** (or `src/manifest` has another
  major.minor), then stamps `build_version` = patch × 1000 + (run number mod 1000);
- builds, runs the unit tests and Roku's Static Channel Analysis (sca-cmd, checked against `SCA_SHA256`);
- checks that `src/images/ui` matches `scripts/make-ui-assets.py` (the `ui-assets` job);
- the `release` job writes `SHA256SUMS.txt`, records a signed **build provenance attestation** for `cove-roku.zip`, and
  creates a **draft** release with `cove-roku.zip` and `SHA256SUMS.txt`.

If the tag build fails because of the version, delete the tag (admin), merge the version PR, and tag again.

## 4. Verify the draft

```sh
mkdir -p /tmp/vX.Y.Z && cd /tmp/vX.Y.Z
gh release download vX.Y.Z -R ldoctoru/cove-roku
sha256sum -c SHA256SUMS.txt                                   # cove-roku.zip: OK
gh attestation verify cove-roku.zip -R ldoctoru/cove-roku     # provenance: built by this repo's workflow
python3 -c "import zipfile; print(zipfile.ZipFile('cove-roku.zip').read('manifest').decode())" | grep _version
```

`major_version` and `minor_version` must be X and Y, and `build_version` must be in the patch's range: 0–999 for
X.Y.0, 1000–1999 for X.Y.1, and so on. If possible, sideload this exact zip once and check Settings → About.

## 5. Publish

```sh
gh release edit vX.Y.Z -R ldoctoru/cove-roku --notes-file notes.md --draft=false --latest
```

## 6. Roku Developer Dashboard (store or beta app)

1. Package the zip as a signed `.pkg` on a Roku in developer mode (`http://<roku-ip>` → Packager, with the app's signing
   key; keep the key and its password private and backed up).
2. Dashboard → the app → **App package** → upload the `.pkg`. The dashboard runs Static Channel Analysis again.
3. Update the store listing if needed, then publish (beta) or schedule publishing (public).

Every upload needs a higher version than the last one: a new patch, minor or major version always gives one.

## After the release

- Development and main now contain the same code; new work branches from Development again.
- If Roku updated `sca-cmd.zip`, the build fails with "sca-cmd.zip checksum mismatch": download it, check it, and
  update `SCA_SHA256` in `build.yml` in its own PR.
