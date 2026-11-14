# SapphireOS

16-bit BIOS boot sector and 32-bit NASM kernel. QEMU boots a VGA text shell. COM1 prints `SapphireOS ready` at startup.

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
qemu-system-i386 -drive format=raw,file=build/sapphireos.img -serial stdio
```

Headless serial check:

```sh
timeout 8 qemu-system-i386 -drive format=raw,file=build/sapphireos.img -serial stdio -display none
```

## Shell

Prompt is `sapphire>`. Backspace deletes a character. Enter runs the line.

- `help` — list commands
- `clear` — clear the screen
- `about` — version and description
- `echo TEXT` — print TEXT
- `color HH` — set the VGA attribute to the hex byte HH
- `reboot` — reboot by pulsing the keyboard controller

An unknown command prints `Unknown command`.
