# Fix touchpad disable-while-typing with keyd

Use this when the touchpad still responds while typing on the laptop keyboard
and keyd is running. keyd grabs the physical keyboard and sends keystrokes to
Hyprland through a virtual keyboard. Libinput may pair the touchpad with the
physical keyboard instead of the virtual one, so typing does not trigger the
touchpad's disable-while-typing (DWT) behavior.

## 1. Check the current state

Confirm Hyprland has DWT enabled:

```bash
hyprctl getoption input:touchpad:disable_while_typing
```

The result should include `bool: true`.

Confirm keyd is running and provides its virtual keyboard:

```bash
systemctl is-active keyd
grep -H 'keyd virtual keyboard' /sys/class/input/event*/device/name
```

## 2. Install the libinput quirk

The quirk in `local-overrides.quirks` marks only `keyd virtual keyboard` as an
internal keyboard, allowing libinput to pair its typing events with the internal
touchpad.

If `/etc/libinput/local-overrides.quirks` does not exist yet, install the
dotfiles copy:

```bash
sudo install -Dm644 ~/dotfiles/libinput/local-overrides.quirks \
  /etc/libinput/local-overrides.quirks
```

If that file already contains other local quirks, preserve them and append only
the `[Keyd virtual keyboard is internal]` section from
`local-overrides.quirks`. Do not add the same section twice.

## 3. Restart Hyprland

Log out of the Hyprland session and log back in. A config reload is not enough:
libinput reads device quirks when it initializes devices.

## 4. Verify the pairing

Check the current Hyprland log for both the touchpad and keyd keyboard pairing:

```bash
sig=$(basename "$(find "$XDG_RUNTIME_DIR/hypr" -mindepth 1 -maxdepth 1 -type d | head -n1)")
grep -i 'dwt activated' "$XDG_RUNTIME_DIR/hypr/$sig/hyprland.log" | tail
```

The expected line names both devices, similar to:

```text
dwt activated with SYNA2BA6:00 06CB:CFD8 Touchpad<->keyd virtual keyboard
```

Then type while a hand rests on the touchpad and confirm it does not move the
pointer. DWT suppresses touchpad input temporarily after typing; it does not
permanently disable the touchpad. Libinput palm detection is a separate feature.

## Remove the quirk

Delete the `[Keyd virtual keyboard is internal]` section from
`/etc/libinput/local-overrides.quirks`, then log out of Hyprland and back in.
