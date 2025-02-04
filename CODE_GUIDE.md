# Code organization

Writing even a small mod takes some organization to not end up with
complicated and brittle code. This mod is also a testbed to try out
some different techniques on how to structure a mod:

## Root folder

- LICENSE          - mod license
- changelog.txt    - factorio mandated changelog file. See https://wiki.factorio.com/Tutorial:Mod_changelog_format
- info.json        - mod description. See https://wiki.factorio.com/Tutorial:Mod_structure#info.json
- thumbnail.png    - Thumbnail to be shown on the mod portal and in the mod browser in-game. Ideally a 144x144px image file. (https://wiki.factorio.com/Tutorial:Mod_structure#Files)

- settings.lua         - entry point for the settings phase
- data.lua             - entry point for prototype stage, phase 1
- data-updates.lua     - entry point for prototype stage, phase 2
- data-final-fixes.lua - entry point for prototype stage, phase 3
- control.lua          - entry point for runtime stage

## Folders

- locale     - mod localizations (factorio mandated)
- migrations - data migrations from older versions of the mod code (factorio mandated)
- graphics   - contains all the image assets for the mod

- framework  - [GENERIC]      The mod framework code. Not mod specific.
- lib        - [MOD SPECIFIC] lua code that can be used in any phase.
- prototypes - [MOD SPECIFIC] lua code for the data phase.
- scripts    - [MOD SPECIFIC] lua code for the runtime phase.
