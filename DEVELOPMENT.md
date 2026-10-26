# Development and verification record

## Acceptance and scope

Darkroom is an independent native GTK photo editor. This initial increment must:

- Open a supported local photo and display a size-bounded preview.
- Rotate the preview clockwise and reset it without writing the original.
- Preserve the current preview when another file cannot be loaded.
- Start a real GTK/libadwaita window and exercise editing actions under Xvfb.
- Build and test through Meson, install desktop resources, and build an inspectable Debian package.
- Configure checks for pull requests, pushes to main, and checks-only manual dispatch; publish the tested package and checksum only on successful trusted pushes to main.

RAW development, export, catalogs, adjustment controls, and full-resolution editing are not included. All edits affect the preview only.

## Historical foundation structural decision

This section records the foundation before repository activation. The repository started empty. The read-only assessment found no useful tidying candidate; this is not a Never decision or an executed green baseline. No preparatory or follow-up tidying was performed. Work is on `feat/initial-gtk-app` in the exclusive existing worktree; a separate worktree is not feasible before an authorized initial commit. No commit or publication was performed.

One implementation agent owned the initial test/implementation cycles, packaging, automation, and documentation. It reached its 10-minute limit after creating the package and was not restarted. After independent review, the coordinator sequentially completed test-isolation corrections, regression coverage, and verification; there were no simultaneous writers.

## Evolving scenarios

1. Load a real PNG into the preview.
2. Rotate a rectangular preview clockwise, preserving original file bytes.
3. Reset rotation and wrap four rotations back to the original orientation.
4. Invalid input preserves the current preview; opening a different image resets rotation.
5. Native startup, enabled/disabled actions, preview updates, and reset under Xvfb.

6. Bound large previews while preserving aspect ratio and honor embedded JPEG orientation.
7. Restore exact pixels on reset; replace the reset baseline when opening a second photo.
8. Reject truncated input without losing the current preview or reset baseline.

## Historical foundation verification

The following results predate repository activation. AppStream validation then used a missing-homepage override because no real remote existed; the activation change removes that override and adds the confirmed homepage.

Verified locally on Ubuntu 26.04.1 amd64 with Vala 0.56.18, Meson 1.10.1, GTK 4.22.4, and libadwaita 1.9.1. This does not establish Ubuntu 24.04 compatibility.

### Original behavioral TDD cycles

The implementation agent's original tool results were recovered from the current session record after its timeout. These are recorded executions by that agent, not newly manufactured failures or inferred history. Selected command/results are retained locally in `build/verification/initial-tdd-history.txt`:

| Scenario | Observed red from `meson test -C build --suite unit --print-errorlogs` | Following green |
| --- | --- | --- |
| Load a photo without upscaling | Preview was null; first implementation then returned width 1067 instead of 2 | Unit executable passed |
| Clockwise rotation | Width remained 2 instead of becoming 3 | Unit executable passed with loading regression |
| Reset | Width remained 3 instead of returning to 2 | Unit executable passed with preceding regressions |

An earlier Vala literal-type compilation error was a setup failure, **not** a behavioral red. Missing-input preservation was retained as an already-passing regression.

### Independent review corrections

- Added a display assertion to the native GUI smoke test before creating its window. With no external backend override, the test failed because GTK selected `wayland-0` instead of Xvfb's `:100`. Setting `GDK_BACKEND=x11` in the Meson test environment made the unchanged assertion and full suite pass. Evidence: `build/verification/gui-isolation-red.log` and `gui-isolation-green.log`.
- Strengthened reset to compare every pixel and added large-image scaling, embedded EXIF orientation, second-photo replacement, and truncated-image preservation scenarios. All passed against the existing implementation; no artificial red or production change was needed. Evidence: `build/verification/preview-regressions.log`.
- Parsed the workflow with Ruby/Psych, asserted PR/main triggers and release permissions/gates, and checked every embedded script with `bash -n` and `shellcheck --shell=bash`. Explicit directory-change failure handling resolved ShellCheck SC2164. All final checks passed; this is static validation, not an Actions run. Evidence: `build/verification/workflow-check.log`.

### Final build, tests, and package

- `meson compile -C build`: passed.
- `env -u DISPLAY -u WAYLAND_DISPLAY -u GDK_BACKEND -u DBUS_SESSION_BUS_ADDRESS meson test -C build --print-errorlogs`: **4 Meson entries passed, 0 failed**: eight GLib preview scenarios, one native-window scenario, desktop-entry validation, and AppStream validation. Evidence: `build/verification/headless-green.log`.
- `dpkg-buildpackage -us -uc -b`: passed, including all four Meson entries during packaging. Evidence: `build/verification/package-final.log`.
- Built artifact: `../darkroom_0.1.0-1_amd64.deb`. `dpkg-deb --info`, `--contents`, and extraction succeeded. The executable, desktop entry, icon, AppStream metadata, generated runtime dependencies, and full GPL license were present. Extracted metadata validated, and the installed license matched `LICENSE`.
- The extracted executable's `--help` succeeded. An isolated Xvfb/private-D-Bus launch remained running until a three-second timeout (expected exit 124), with no critical/error messages. This verifies startup, not interactive use or package installation. Evidence: `build/verification/package-launch.log` and `package-launch-result.txt`.
- `cmp LICENSE /usr/share/common-licenses/GPL-3`: passed. No dependencies or package were installed on the host.

Generated logs are ignored local artifacts under `build/verification/`; this document preserves the essential results if that directory is cleaned.

## Repository activation

This section records local activation verification before the remote runs below.

The public [source repository](https://github.com/gstn-caruso/darkroom) now exists and is configured as `origin`. The workflow adds checks-only manual dispatch while preserving PR/main checks and the push-to-main-only release gate. The confirmed repository URL is the AppStream homepage; validation no longer overrides the missing-homepage warning. No useful structural tidying was identified, and application behavior and test sources remain unchanged.

Local activation acceptance on the same Ubuntu 26.04.1 toolchain:

- Before editing, `meson test -C build --print-errorlogs` passed all four entries. Configuration checks identified the absent dispatch trigger, missing homepage, and remaining overrides; `appstreamcli validate --no-net data/org.darkroom.Darkroom.metainfo.xml` exited 3 with `url-homepage-missing`. These are configuration gaps, not application TDD reds. Evidence: `build/verification/activation-baseline.log`, `activation-config-before.log`, and `activation-metadata-before.log`.
- After editing, `ruby build/verification/activation-check.rb` passed workflow parsing, PR/main/dispatch acceptance, the release gate matrix (including no dispatch publication on main), and permission assertions. Every embedded workflow script passed `bash -n` and `shellcheck --shell=bash`. Evidence: `build/verification/activation-config-after.log`.
- `meson compile -C build` and `meson test -C build --print-errorlogs` passed: four entries, zero failures, with the same eight preview and one GUI scenarios. AppStream validation now runs without overrides. Evidence: `build/verification/activation-compile.log` and `activation-tests.log`.
- `dpkg-buildpackage -us -uc -b` passed, including all four test entries. Inspection and extraction of `../darkroom_0.1.0-1_amd64.deb` succeeded; the extracted desktop entry and AppStream metadata validated without overrides, and the packaged metadata matched the source. Evidence: `build/verification/activation-package.log` and `activation-package-inspection.log`. No package or dependency was installed.

## Remote CI, release, and protection verification

The following evidence was supplied by the coordinator, who observed the runs and GitHub API responses. It was not independently re-executed during this documentation-only update.

- The public [repository](https://github.com/gstn-caruso/darkroom) has `origin` configured and `main` as its default branch. Initial commit `93855ce5357ae672c9d2f5a5d810fe1ffacdf732` was published after independent staged review. `main` was established at that same commit only after bootstrap CI passed.
- The [bootstrap run 40246332918](https://github.com/gstn-caruso/darkroom/actions/runs/40246332918), triggered by `workflow_dispatch` on the feature branch, succeeded on Ubuntu 24.04 amd64. Build, all four suite entries (eight preview scenarios, one GUI scenario, desktop and AppStream validation), Debian packaging, package/resource inspection, and artifact upload passed. The release job was skipped as intended.
- The [first main-push run 40246509296](https://github.com/gstn-caruso/darkroom/actions/runs/40246509296) succeeded in both checks and publication, including the artifact download/checksum/publish step. The [snapshot-2-1 prerelease](https://github.com/gstn-caruso/darkroom/releases/tag/snapshot-2-1) targets exactly `93855ce5357ae672c9d2f5a5d810fe1ffacdf732`, confirmed through the tag/commit API. Uploaded assets are `darkroom_0.1.0+ci.2.1-1_amd64.deb` (21,952 bytes) and `SHA256SUMS` (100 bytes). The asset API reports the Debian package digest as `sha256:2dd458b75d6cf159ab65d521a5c11e2ee6d43ea6a97e7326d93c1bf9fad842d4`.
- The optional bootstrap artifact download failed with HTTP 503 due to a storage egress limit. This historical failure does not block local verification of the later snapshot-4-1 release, recorded below.
- Branch protection was confirmed through PUT/GET responses: PR required; required check `Test and package (Ubuntu 24.04 amd64)` from GitHub Actions app `15368`; strict/up-to-date checks and administrator enforcement enabled; force pushes and deletion disabled; conversation resolution required. Required approving reviewers are zero for the solo owner, so manual approval is not a mandatory protection rule.
- Actions are enabled with default workflow permissions set to read. `GITHUB_TOKEN` cannot approve PR reviews; only the release job explicitly requests write permission for publication.
- [PR #1](https://github.com/gstn-caruso/darkroom/pull/1), with independently reviewed head `36e14ceb8da32610b33b47e3e836ed7536aa8353`, was `BLOCKED` while the required check was in progress and became `CLEAN` only after it passed. [PR run 40247013668](https://github.com/gstn-caruso/darkroom/actions/runs/40247013668) succeeded with `Test and package (Ubuntu 24.04 amd64)` passing and publication skipped. `gh pr merge 1 --merge --match-head-commit 36e14ceb8da32610b33b47e3e836ed7536aa8353` succeeded without `--admin` or bypass at `2026-10-25T23:59:25Z`, creating merge commit `bf970debf6c2f01e6cb840d589987f20ee195f8f`.
- The resulting [main-push run 40247181124](https://github.com/gstn-caruso/darkroom/actions/runs/40247181124) passed checks and publication on Ubuntu 24.04 amd64 at that exact merge commit. The [snapshot-4-1 prerelease](https://github.com/gstn-caruso/darkroom/releases/tag/snapshot-4-1) targets `bf970debf6c2f01e6cb840d589987f20ee195f8f`, confirmed through the tag API, and contains `darkroom_0.1.0+ci.4.1-1_amd64.deb` (21,956 bytes) and `SHA256SUMS` (100 bytes).
- The coordinator downloaded those assets with `gh release download snapshot-4-1 --pattern '*.deb' --pattern SHA256SUMS` into `/home/gaston/Code/darkroom/build/verification/release-snapshot-4-1`. `sha256sum --check SHA256SUMS` passed; the package SHA-256 is `fc90a0dedfa7593505890aaa7ead85808ef9dd7c4a6752087d2b4a4c827cd1ea`. `dpkg-deb --info` and `dpkg-deb --contents` passed, confirming version `0.1.0+ci.4.1-1`, architecture `amd64`, generated runtime dependencies, and the application, resources, and license. Evidence: `/home/gaston/Code/darkroom/build/verification/release-snapshot-4-1-inspection.log`. No installation was performed.

The standing UI constraint is now explicit in [AGENTS.md](AGENTS.md) and [CONTRIBUTING.md](CONTRIBUTING.md): Vala with native GTK 4 widgets and native libadwaita GNOME components throughout, no Electron, WebViews, or web-based UI. Native GTK CSS and image textures are allowed. No UI rewrite or runtime change is part of this documentation update.

## Remaining limits

- No actionlint executable was available during local activation; the historical YAML/shell checks remain static evidence, distinct from the observed GitHub runs.
- The historical local `.deb` build used Ubuntu 26.04.1. The Ubuntu 24.04 amd64 snapshot-4-1 distribution package has now been downloaded, checksummed, and inspected locally, but this does not establish installation or interactive behavior. No host installation or desktop-menu integration was tested. The native chooser has not been exercised interactively.
- Expected non-fatal diagnostics include generated-C unused-variable warnings, a newer-GTK deprecation warning for the compatible GdkPixbuf texture adapter, and Xvfb acceleration warnings. Packaging also warns about the placeholder `darkroom@localhost` maintainer address; replace it with the real project contact when one is selected.
- Preview-only editing, synchronous decoding, and the feature exclusions described in the README remain intentional limitations.
