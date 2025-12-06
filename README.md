# Abstract Schematic Editor

## Description

A simple schematic editor with the aim to have a circuit drawing style similar to the infamous Dr. Behzad Razavi.

**Note**: 

This version is still in beta.

The symbol quality may not be up to your liking so does the graphics or the performance.

All of that will get better in the future.

## Download & Setup

### From Rlease Binaries

You can download the program executable and supporting libraries from the binary release link https://github.com/AhmedLilah/AbstractSchematic/releases, the program should be provided as static executable that doesn't need to be setup. 


### From Source Code 

- Download the repo. 
- Make sure you have the Odin compiler setup.
- run this command `odin build . -out="AbstractSchematic.exe" -o=aggressive -target=windows_amd64 -subsystem=windows` to compile the code.
- run the program.

## User Interface

the program starts in normal mode.

### Global Shortcuts

- **F11**: Full Screen.
- **Alt + G**: fine grid.
- **G**: toggle grid.

### Nomra Mode 

- **F**: reset the zoom.
- **O**: reset to the origin.
- **I**: component insert mode.
- **W**: wiring mode.
- **Space + Left Click and move**: pan the schematic.
- **Ctrl + S**: save.
- **Ctrl + Z**: undo.
- **Mouse Wheel**: zoom.

### Instantiation Mode

- **Esc**: cancel and return to normal mode.
- **F**: reset the zoom.
- **O**: reset to the origin.
- **Tab**: cycle through component models.
- **R**: rotate component.
- **V**: flip vertically.
- **H**: flip horizontally.
- **Space + Left Click and mode**: pan the schematic.
- **Ctrl + S**: save.
- **Left Click**: place instance.
- **Mouse Wheel**: zoom.

### Wiring Mode

- **Esc**: cancel and return to normal mode.
- **Left Click**: place wire point.
- **Shift + =**: increase wire thickness.
- **Shift + -**: decrease wire thickness.

### File Saving
- **Esc**: cancel and return to normal mode.
- **Keys or Backspace**: wire the file name without the extension.
- **Enter**: commit the save action.

## Feature Requests / Buggs

make a github issue with your request or problems.
