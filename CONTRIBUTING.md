# Contributing

All project code, comments, UI, documentation, and contribution discussions are in English. Contributions must be compatible with GPL-3.0-or-later. AppStream metadata is CC0-1.0.

## Test-driven changes

1. Work on a feature branch. Inspect the working tree before editing; preserve other contributors' work. Keep one writer per coherent change.
2. List observable scenarios. Pick one pending scenario and add a behavior test before implementation.
3. Run `meson test -C build --suite unit --print-errorlogs` and observe the missing behavior. Compiler errors, unavailable tools, or a broken display are setup failures, not behavioral red tests. If the scenario already passes, keep it as a regression rather than manufacturing a failure.
4. Make the smallest useful implementation. Run the new test and all previous tests.
5. Refactor only while green. Evaluate whether a small structural preparation would help; no tidying is a valid choice. Keep structural changes separate from behavior changes and use the same unchanged tests before and after.
6. Run `meson compile -C build`, `meson test -C build --print-errorlogs`, and `dpkg-buildpackage -us -uc -b` before proposing a merge. Request independent review. Do not bypass required checks or publish without permission.

Initialize the runner with `meson setup build --prefix=/usr`. `--suite unit` does not require a display. The full suite starts its own Xvfb display and private D-Bus session; it does not need a running desktop. Metadata checks are part of the suite. Do not skip tests for release packaging.

`PhotoPreview` owns image loading and preview transformations without GTK widget dependencies. `MainWindow` translates native UI actions into preview operations. Tests use actual PNG fixtures and real GTK widgets, not mock interaction choreography. Never write an input file from editing operations. Adding export requires a separate explicit contract and tests.

Keep APIs compatible with GTK 4.10 and libadwaita 1.4 minimums. CI uses Ubuntu 24.04 amd64 (GTK 4.14 / libadwaita 1.5); testing on a newer host alone does not prove that target. Submit changes to [gstn-caruso/darkroom](https://github.com/gstn-caruso/darkroom). Pull requests and main pushes are configured to run tests and package checks; require `Test and package (Ubuntu 24.04 amd64)` before merging. Manual `workflow_dispatch` runs the same checks and builds the package but never publishes. Only successful main pushes are configured to publish `.deb` prereleases to [Releases](https://github.com/gstn-caruso/darkroom/releases). The remote exists, but real CI execution, required-check protection, and first publication remain pending; do not claim they succeeded without observed evidence.
