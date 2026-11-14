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
qemu-system-i386 -drive format=raw,file=build/sapphireos.img -vga std -serial stdio -display gtk,zoom-to-fit=off,grab-on-hover=off
```

Headless serial check:

```sh
timeout 8 qemu-system-i386 -drive format=raw,file=build/sapphireos.img -vga std -serial stdio -display none
```

If the video mode cannot be set, SapphireOS keeps the text shell and prints `VBE mode set failed`.

## Desktop

A menu bar sits on top and a dock sits along the bottom. File, Edit, View, and Window open menus. Red closes a window, yellow minimizes it, and green zooms it. Dock icons bring a window back. The clock is 12-hour.

Move the mouse to move the cursor. Drag a window by its title bar. Drag the bottom-right corner to resize. Click a window, or its dock icon, to raise it.

File → New Terminal opens another Terminal (up to three). Each has its own buffer; typing goes to the frontmost Terminal. Closing hides a slot so New Terminal can reuse it. The dock restores the primary Terminal and About.

The Terminal window runs the shell. Backspace deletes a character. Enter runs the line.

`make run` shows the 800x600 framebuffer at 1:1 in a GTK window (`zoom-to-fit=off`), so the desktop stays 4:3. On-screen text is 8 pixels wide and 16 tall.

## Shell

Prompt is `sapphire>`.

- `help` — list commands
- `clear` — clear the terminal
- `about` — version and description
- `echo TEXT` — print TEXT
- `color HH` — set the terminal attribute to the hex byte HH
- `reboot` — reboot by pulsing the keyboard controller

An unknown command prints `Unknown command`.
