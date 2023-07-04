# Spectre OS

[![GitHub last commit](https://img.shields.io/github/last-commit/Xaaf/SpectreOS?style=flat-square)](https://github.com/Xaaf/SpectreOS/commits)
[![GitHub issues](https://img.shields.io/github/issues-raw/Xaaf/SpectreOS?style=flat-square)](https://github.com/Xaaf/SpectreOS/issues)
[![GitHub repository size](https://img.shields.io/github/repo-size/Xaaf/SpectreOS?style=flat-square)]()
[![GitHub total lines](https://img.shields.io/tokei/lines/github/Xaaf/SpectreOS?style=flat-square)]()
[![GitHub contributors](https://img.shields.io/github/contributors-anon/Xaaf/SpectreOS?style=flat-square)]()

> An open-source operating system from scratch!
## About SpectreOS
SpectreOS is an operating system that I started working on looking for something fun to do, when not working on my other projects. The logical conclusion was to start learning how operating systems work and to make one myself! There's no guarantee to the program being in a state where it even functions for the near future, as making an operating system is not a small task. If you're interested in following development, be sure to star this repo!

## Getting Started
If you want to have a look at SpectreOS in its current state, here's how to do it!

### Requirements
On an apt-based system, you can use the following command to install all required packages to get started - `sudo` privileges might be required.
```sh
apt install qemu ovmf gnu-efi binutils-mingw-w64 gcc-mingw-w64 xorriso mtools
```

At this moment, you'll also need to have the [Watcom compiler](https://github.com/open-watcom/open-watcom-v2/) installed, for the freestanding C code.

For debugging, you'll also need these packages.
```sh
apt install bochs bochs-sdl bochsbios vgabios
```

### Building
1. Clone the repo 
```sh
git clone https://github.com/Xaaf/SpectreOS.git
```
2. Build the project and run it!
```sh
make run
```

## Roadmap
This roadmap will list features that are possible to be implemented in the somewhat near future. Things like "having a GUI" and such will be added later down the line, if this project progresses that far! Note that the order in which these are listed does not define the order in which I'd like to implement them. This is more so just a rough sketch of what's to come for SpectreOS!
- [ ] Move the kernel into C
- [ ] Implement a simple logging system
- [ ] Interruption and execution handling
- [ ] Memory mapping & the heap (`malloc` and `free`)
- [ ] Capturing keyboard input

## Credits
For a list of credits and acknowledgements, check the [credits](https://github.com/Xaaf/SpectreOS/blob/main/CREDITS)!