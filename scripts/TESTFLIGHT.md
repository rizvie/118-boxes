# Shipping 118 Boxes to the phone

```sh
scripts/testflight-upload.sh
```

Archives Release, exports, and uploads in one go. The build then processes in
App Store Connect for a few minutes before it appears in TestFlight.

## Before the first build can be installed

A build being `VALID` and `READY_FOR_BETA_TESTING` is **not** enough to install
it. It also has to be distributable to a group, and a new app record has none,
so TestFlight on the phone simply shows nothing. Run this once:

```sh
TESTFLIGHT_TESTER_EMAIL=you@example.com \
TESTFLIGHT_TESTER_FIRST=First TESTFLIGHT_TESTER_LAST=Last \
  python3 scripts/setup-testflight-group.py
```

It is idempotent, and the tester details come from the environment rather than
the file because this repository is public. The group is created with
`hasAccessToAllBuilds`, so every future upload is available without re-running
anything.

## What it needs

- `~/.clipper-asc.env` with `ASC_KEY_ID` and `ASC_ISSUER_ID`. One App Store
  Connect API key covers a whole team, so this reuses the existing key rather
  than creating a new one. Override the path with `BOXES118_ASC_ENV`.
- `~/.appstoreconnect/private_keys/AuthKey_<ASC_KEY_ID>.p8`, already present.
- XcodeGen on PATH (`brew install xcodegen`). The script regenerates the project
  first so `project.yml` stays the source of truth.

## The team ID trap

`project.yml` originally pointed at a personal team, which happened to be the
only signing identity in the local keychain. That is **not** the team that owns
this app.

`io.riz.boxes118` is registered under the same team as my other apps. Archiving
against the wrong team fails to find a matching provisioning profile.

This never showed up during development because every simulator build ran with
`CODE_SIGNING_ALLOWED=NO`, so the team was never exercised. Corrected in both
`project.yml` and `ExportOptions.plist`. If you ever see "no profile for team",
check those two agree.

## Build numbers

`ExportOptions.plist` sets `manageAppVersionAndBuildNumber` to true, so Xcode
picks the build number at upload. `project.yml` pins `CURRENT_PROJECT_VERSION`
to 1, and App Store Connect rejects a repeat of a build number it has already
seen, so without this the second upload would fail.

To bump the marketing version for a real release, edit `MARKETING_VERSION` in
`project.yml`.

## What to check on the actual device

Everything up to now was verified on the simulator, which cannot tell you about:

- **Haptics.** `Haptics.right()` and `wrong()` are wired but have never fired on
  real hardware.
- **Speech.** `AVSpeechSynthesizer` timing and voice availability differ from the
  simulator. The Settings voice picker only lists voices installed on that
  device, so the list will look different from the Mac's.
- **The table.** 118 cells in a `LazyVGrid` scrolling sideways. Fine on a
  simulator with a desktop GPU; worth watching on a phone.
- **First launch.** The intro only shows once, so delete the app between tests
  if you want to see it again.
