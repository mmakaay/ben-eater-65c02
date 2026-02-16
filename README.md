# 65C02 breadboard computer

This repository contains code for the Ben Eater's breadboard computer.
See Ben's website at [https://eater.net](https://eater.net) for many useful resources
and a very binge-worthy collection of explanation videos (only binge-worthy,
if you are into this kind of thing, of course).

The main goal of this repository is to provide useful BIOS functionality (hardware
drivers and abstraction), and to provide useful stdlib subroutines and macros to
include in your own programs. Just add your own application code, to get your
breadboard computer to do fun stuff.

Projects are built on top of the BIOS functionality. A project starts out by including
the BIOS code, and implementing the subroutine `main` to tell the computer what to do
after the BIOS has initialized.

## Hello, world

The mandatory example for any project:

```asm
.include "bios/bios.s"

hello:
    .asciiz "Hello, world!"

main:
    ldx #0                     ; Byte position to read from `hello`
@loop:
    lda hello,x                ; Read next byte
    beq @done                  ; Stop at terminating null-byte
    sta LCD::byte              ; Line the byte up for the LCD display
    jsr LCD::write_when_ready  ; Wait for LCD display to be ready, and then send byte
    inx                        ; Move to the next byte position
    jmp @loop                  ; And repeat
@done:
    jmp BIOS::halt             ; Halt the computer
```

What you can see in here, is that hardware is abstracted by the BIOS, and that the code
only has to worry about providing the required bytes to the LCD display.

This code is also available as a project in `projects/hell-world`.

## Writing assembly code

Wasm is what Ben starts out with in his videos, but later on he uses the "cc65" suite.
This suite provides *a lot* of useful features, and I have written all assembly code
from this repository based on this.

The suite can be built using:

```bash
git clone https://github.com/cc65/cc65
cd cc65
make
```

Documentation at: https://cc65.github.io/doc/

## Configure the build

To support different configurations, you have to provide a configuration file in
`src/config.s`. This configuration file can for example be used to configure what
VIA pins to use for the LCD display.

Sounds difficult? No worries... the bios code will use the hardware layout as
used by Ben in his tutorial videos by default, so all you have to do to get started,
is copy `src/config.s.example` to `src/config.s`. Only when you want to tweak the
hardware configuration, you'll have to change settings from the config.

For information on configuration options, see the `config.s` file.

## Build a ROM

To build a ROM from assembly code, a `Justfile` is provided, that can be used
to build the ROM images from `projects/*`.

The `just` tool is a lot like `make`, only it is more about performing tasks
than about build structuring, and it allows for hierarchical `Justfile`s in
the directory structure. It can be installed using `brew install just`.

Documentation at: https://just.systems/man/en/

Some commands that can be used:

```bash
cd projects/some-project
just build  # Compiles *.s files, and links them into a `rom.bin`.
just write  # Writes `rom.bin` to EEPROM (given you use AT28C256 like Ben)
```

It is not required to use `just` of course. You can also execute the
required build commands by hand. Take a look at the Justfile as a starting
point for this.

## T48 EEPROM writer

For writing the ROM, I use a T48 writer.

Lesson leared: Do connect the device directly to a USB-C port on the MacBook.
It won't work when connected to a HUB, recognizable by a blinking LED.

There is no vendor software for MacBook, but the open source application
`minipro` can be used. This can be installed from homebrew with
`brew install minipro`.

## Write an EEPROM

To write a ROM image to an EEPROM:

```bash
minipro -p AT28C256 -w rom_image.bin

# or equivalent

just write
```

The EEPROM might be write protected. In that case, the extra option `-u` can
be used. The `minipro` application will warn about write protected EEPROMs
and suggest this flag. I had to do disable write protection when I wrote to
the EEPROM for the first time.

```bash
minipro -u -p AT28C256 -w rom_image.bin

# or equivalent

just write-u
```
