# lvgl_pc_minimal

This repository is based on the original LVGL PC port project:

- https://github.com/lvgl/lv_port_linux

It is a separate repository created to provide a smaller and cleaner starting point for new LVGL projects on PC.

## Goals

- keep dependencies to a minimum
- avoid git submodules in the project structure
- remove bundled examples and demos
- provide a practical boilerplate for starting a new LVGL application on a PC target

## UI Layer

The UI is intended to be generated with EEZ Studio:

- https://www.envox.eu/studio/

This repository is structured around an EEZ Studio generated UI integrated with LVGL.

EEZ Studio can also generate EEZ Flow logic for UI-side automations.
EEZ Flow is the visual flow programming environment inside EEZ Studio and can be used to implement parts of the UI behavior without writing all interactions manually in C/C++.

Typical uses for EEZ Flow include:

- page navigation and screen transitions
- widget interactions and event handling
- simple UI logic and data transformations
- bindings between native variables and visual components
- lightweight automation logic driven directly from the UI project

This is useful when the UI designer wants to keep presentation logic and simple automations inside the EEZ Studio project, while the application backend remains responsible for field communication, state management, and business logic.

## Application Architecture

The project keeps the LVGL and generated UI layer in C, while the application backend can be implemented in C++.

This makes it easier to build application-side components such as:

- fieldbus integration
- industrial protocol adapters
- networking services
- state machines and business logic

The current direction is to use a C++ backend behind a small C-compatible interface, so the UI stays isolated from runtime, communication, and control logic.

## LVGL Backends

This project keeps the backend abstraction from the original Linux LVGL port, so different display/input backends can be selected depending on the target environment.

Examples include:

- SDL2 for desktop development and simulation
- DRM for direct rendering on Linux systems without a full desktop environment
- FBDEV for framebuffer-based targets
- Wayland for Wayland-based desktop systems
- X11 for X11-based desktop systems
- EVDEV for input device support

The exact set of enabled backends depends on how LVGL and the project are configured at build time.

Backend support must be enabled in `lv_conf.defaults`.
In practice, only the backends enabled there will be compiled into the final executable and available at runtime.

The backend can be selected at runtime with the `-b` option:

```bash
./build/lvglsim -b sdl
./build/lvglsim -b drm
./build/lvglsim -b x11
```

To list the supported backends compiled into the executable:

```bash
./build/lvglsim -B
```

Other useful runtime options include:

- `-W` to set the window width
- `-H` to set the window height
- `-f` for fullscreen
- `-m` to start maximized
- `-R` to set display rotation

This makes the repository useful both for desktop simulation during development and for Linux-based targets that need a different LVGL backend.

## Purpose

The main purpose of this repository is to serve as a reusable boilerplate for new desktop LVGL projects, especially when the UI is designed in EEZ Studio and the runtime/backend needs to connect to field devices, external services, or application logic implemented in C++.

## Build

Example build commands:

```bash
cmake -S . -B build
cmake --build build
```
