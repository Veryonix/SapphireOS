# SapphireOS

16-bit BIOS boot sector and 32-bit NASM kernel. QEMU boots an 800x600 desktop (VBE mode `0x143`, 32 bits per pixel). COM1 prints `SapphireOS ready`, then `desktop up`.

## Build

```sh
make all
```

Raw disk image: `build/sapphireos.img`

```sh
make clean
```

## Run

```sh
make run
```

That runs:

```sh
qemu-system-i386 -drive format=raw,file=build/sapphireos.img -vga std -serial stdio
```

Headless serial check:

```sh
timeout 8 qemu-system-i386 -drive format=raw,file=build/sapphireos.img -vga std -serial stdio -display none
```

If the video mode cannot be set, SapphireOS keeps the text shell and prints `VBE mode set failed`.

## Desktop

A menu bar sits on top and a dock sits along the bottom. File, Edit, View, and Window open menus. Red closes a window, yellow minimizes it, and green zooms it. Dock icons bring a window back. The clock is 12-hour.

Move the mouse to move the cursor. Drag a window by its title bar. Click a window, or its dock icon, to raise it.

The Terminal window runs the shell. Backspace deletes a character. Enter runs the line.

`make run` keeps the QEMU window at the 800x600 aspect ratio (`-display gtk,zoom-to-fit=off`).

## Shell

Prompt is `sapphire>`.

- `help` — list commands
- `clear` — clear the terminal
- `about` — version and description
- `echo TEXT` — print TEXT
- `color HH` — set the terminal attribute to the hex byte HH
- `reboot` — reboot by pulsing the keyboard controller

An unknown command prints `Unknown command`.
