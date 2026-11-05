# Repository Guidelines

## Project Structure & Module Organization

backspin is a dependency-free Swift Package Manager project for a macOS 13+ menu bar app that reverses notched mouse-wheel scrolling while the trackpad keeps natural scrolling.

- `Sources/backspin/`: menu bar lifecycle, the scroll event tap, Accessibility prompts, and login item support.
- `Sources/ScrollCore/`: wheel detection, delta inversion, and the system Natural scrolling lookup; keep independently testable logic here.
- `Tests/ScrollCoreTests/`: XCTest coverage for detection and inversion against synthesized `CGEvent`s.
- `scripts/`: app bundle build, install, launch, and the scroll probe.
- `.build/`: generated binaries and the app bundle; excluded from Git.

## Build, Test, and Development Commands

Use macOS with a Swift 5.9-compatible toolchain. Install `just` to use the repository shortcuts.

- `swift build`: compile the package for development.
- `swift test`: run the XCTest suite.
- `just build`: build the release app bundle at `.build/backspin.app` and verify its signature. Set `BACKSPIN_SIGN_IDENTITY` for a stable local signing identity.
- `just run`: launch the development app; builds it if missing. Rebuild explicitly after source changes.
- `just install`: build and install into `~/Applications` (override with `BACKSPIN_INSTALL_DIR`); quit backspin first.
- `just probe`: print the scroll fields device detection relies on, without altering events.

## Coding Style & Naming Conventions

Follow existing Swift style: four-space indentation, `UpperCamelCase` types, and `lowerCamelCase` methods and properties. Name files after their principal type, such as `ScrollTap.swift`. Keep event logic in `ScrollCore` and AppKit or system integration in the `backspin` target. No formatter or linter configuration is checked in; keep comments limited to non-obvious contracts.

## Testing Guidelines

Use XCTest classes named `*Tests` and descriptive `test...` methods. Build fixtures with `CGEvent(scrollWheelEvent2Source:...)` and assert every delta field, following existing tests. Reproduce bugs before fixing them and rerun the relevant tests afterward. No coverage threshold is configured.

Synthesized events cannot stand in for real devices. For detection or inversion changes, manually verify a notched mouse wheel, the trackpad, and a Magic Mouse if available, with Natural scrolling both on and off, and use `just probe` to record what a new device reports.

## Commit & Pull Request Guidelines

History is a single `Initial release` commit. Write short, imperative subjects describing the change. Pull requests should explain behavior, validation commands and results, and relevant issues. Include screenshots for visible menu changes and update the README's limitations when detection behavior changes.

## macOS Permissions & Configuration

Grant Accessibility access when prompted; the scroll tap cannot start without it. Ad hoc rebuilds invalidate the grant, so remove and re-add backspin in the Accessibility list or sign with `BACKSPIN_SIGN_IDENTITY`. Preserve the `local.backspin` bundle identifier: the Accessibility grant, the login item, and the install script's replacement check all key on it. The tap sits in the session's scroll event path, so its callback must stay fast and always return the event.
