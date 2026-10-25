# Darkroom

An independent native GTK photo editor, written in Vala with GTK 4 and libadwaita. Free software under **GPL-3.0-or-later**.

[Source repository](https://github.com/gstn-caruso/darkroom) · [Releases](https://github.com/gstn-caruso/darkroom/releases)

The UI uses native GTK 4 widgets and native libadwaita GNOME components throughout, never Electron, WebViews, or web-based UI. See [AGENTS.md](AGENTS.md) for project constraints.

## Initial foundation

Open local JPEG, PNG, TIFF, or WebP photos (depending on installed GdkPixbuf loaders), view a preview, rotate clockwise, and reset. Previews fit within 1600 × 1600 pixels, never upscale small images, and apply embedded orientation. Rotation and reset affect only the preview; the original file is never written. Opening another photo discards preview edits. Invalid input leaves the current photo intact.

This is not a complete professional editor. Export, RAW development, catalogs, color management, exposure controls, history, and full-resolution editing are out of scope. Decoding is currently synchronous; very large or untrusted images can consume time and decoder resources.

## Build, test, and run

Requirements: Vala >= 0.56, C compiler, Meson >= 1.0, Ninja, pkg-config, GLib >= 2.76, GTK >= 4.10, libadwaita >= 1.4, GdkPixbuf, Xvfb, xauth, D-Bus, desktop-file-utils, and AppStream CLI. The GUI test uses an isolated X display and a private D-Bus bus without service activation directories.

On an Ubuntu 24.04 development machine, an administrator can install dependencies with:

```sh
sudo apt-get update
sudo apt-get install build-essential meson ninja-build valac pkg-config \
  libglib2.0-dev libgtk-4-dev libadwaita-1-dev libgdk-pixbuf-2.0-dev \
  xvfb xauth dbus desktop-file-utils appstream debhelper devscripts dpkg-dev
```

```sh
meson setup build --prefix=/usr
meson compile -C build
meson test -C build --print-errorlogs
./build/darkroom
```

Tests without a desktop or virtual display:

```sh
meson test -C build --suite unit --print-errorlogs
```

GUI and metadata checks separately:

```sh
meson test -C build --suite gui --print-errorlogs
meson test -C build --suite metadata --print-errorlogs
```

## Debian package

```sh
dpkg-buildpackage -us -uc -b
dpkg-deb --info ../darkroom_0.1.0-1_amd64.deb
dpkg-deb --contents ../darkroom_0.1.0-1_amd64.deb
```

The standard Debian build runs the same tests, installs into a staging directory, and computes runtime dependencies using `dpkg-shlibdeps`. It does not install the package on the host. Output files are written in the parent directory. Native builds use the host architecture and library versions; the path above assumes amd64. Local Ubuntu 26.04 packages may require newer libraries than Ubuntu 24.04 and are **not** the supported distribution artifact.

To inspect files without installation:

```sh
extracted=$(mktemp -d)
dpkg-deb --extract ../darkroom_0.1.0-1_amd64.deb "$extracted"
test -x "$extracted/usr/bin/darkroom"
desktop-file-validate "$extracted/usr/share/applications/org.darkroom.Darkroom.desktop"
appstreamcli validate --no-net "$extracted/usr/share/metainfo/org.darkroom.Darkroom.metainfo.xml"
```

Desktop and AppStream validation run without overrides; the AppStream homepage points to the real source repository.

Installation requires administrator approval and a package built for the host's Ubuntu release and architecture. For the local amd64 build above:

```sh
sudo apt install ../darkroom_0.1.0-1_amd64.deb
```

APT resolves the runtime dependencies recorded in the package; do not force installation on an older distribution. Published CI packages target Ubuntu 24.04 amd64.

## Continuous delivery

`.github/workflows/ci.yml` is configured to check pull requests, every push to `main`, and manual `workflow_dispatch` runs on Ubuntu 24.04 amd64. The checks build the native executable, run unit tests, isolated GUI smoke tests, and desktop/AppStream validation, then build and inspect a `.deb` and upload it as a workflow artifact. Manual dispatch is checks-only, even when targeting `main`; it cannot publish a release. Only a push to `main` with successful checks can enter the dependent release job.

For this desktop application, **deploy means publishing a GitHub prerelease**, not installing on a server. The workflow is configured to publish to [Releases](https://github.com/gstn-caruso/darkroom/releases) after each successful main push, including a merge, with a unique `snapshot-<run>-<attempt>` tag targeting the exact tested commit. The Debian version is `0.1.0+ci.<run>.<attempt>-1`; increment the base version when starting a new release series. The release attaches the same immutable workflow artifact, plus `SHA256SUMS`, with no rebuild. No concurrency cancellation is configured, so main pushes are not intentionally dropped. Checks use read-only repository permissions; only the gated release job requests `contents: write`. No personal secret is needed beyond the automatic `GITHUB_TOKEN`.

**CI and the first main-push publication have succeeded on Ubuntu 24.04 amd64.** The [bootstrap manual run](https://github.com/gstn-caruso/darkroom/actions/runs/40246332918) passed checks and correctly skipped publication. After `main` was established at that tested commit, the [first main-push run](https://github.com/gstn-caruso/darkroom/actions/runs/40246509296) passed checks and publication, producing [snapshot-2-1](https://github.com/gstn-caruso/darkroom/releases/tag/snapshot-2-1) with `darkroom_0.1.0+ci.2.1-1_amd64.deb` and `SHA256SUMS`.

`main` is now the default branch and is protected: pull requests and the up-to-date `Test and package (Ubuntu 24.04 amd64)` check are required, including for administrators; force pushes and deletion are disabled, and conversations must be resolved. Required approving reviews are set to zero for the solo owner. An actual PR merge through this protection and its resulting release remain the next verification step; the successful main-push release does not establish that flow yet.

These remote results were verified by the coordinator; the release package has not been installed or checksummed locally. See [DEVELOPMENT.md](DEVELOPMENT.md) for evidence and remaining limits, and [CONTRIBUTING.md](CONTRIBUTING.md) for the workflow.
