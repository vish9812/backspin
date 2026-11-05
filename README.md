# backspin

A macOS menu bar app that gives the mouse wheel traditional scrolling while the trackpad keeps natural scrolling. macOS ties both to one setting; backspin leaves that setting on and reverses only notched mouse-wheel events.

## Install

Requires macOS 13+, the Swift toolchain, and [just](https://github.com/casey/just).

```sh
just install
open "$HOME/Applications/backspin.app"
```

1. Grant Accessibility access when prompted (System Settings → Privacy & Security → Accessibility).
2. Turn **Natural scrolling** on in System Settings → Trackpad → Scroll & Zoom. The menu shows **Open Trackpad Settings…** while it is off.
3. Optionally enable **Launch at Login** from the menu.

For development: `swift test`, `just build`, `just run`.

## Limitations

- Devices are told apart by whether they report continuous scrolling. A Magic Mouse is continuous, so it is treated like the trackpad. Mice whose drivers emulate smooth scrolling (e.g. Logi Options+ "Smooth scrolling") may be too; turn that option off if the wheel isn't reversed, or use the driver's own scroll direction setting.
- With a new mouse or scroll driver, run `just probe` and scroll each device to see the fields detection depends on.
- Builds are signed ad hoc, so each rebuild invalidates the Accessibility grant. Remove backspin from the Accessibility list and re-add it, or set `BACKSPIN_SIGN_IDENTITY` to a stable signing identity.

## More macOS tools

- [DockNine](https://github.com/vish9812/docknine): Launch pinned Dock apps with Option+1–9.
- [hopapp](https://github.com/vish9812/hopapp): Switch between apps on visible Spaces only.

[MIT License](LICENSE)
