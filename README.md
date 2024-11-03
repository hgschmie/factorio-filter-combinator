# Filter Combinator (reimagined)

This is a re-imagined version of the [Filter combinator by Sil3ntStorm](https://mods.factorio.com/mod/silent-filter-combinator)

The mod provides a combinator that allows filtering of values.

It supports

- Inclusion/Exclusion mode. In inclusion mode, only listed signals are
  passing through the combinator. In exclusion mode, the listed
  signals are removed and all other signals pass through.

- Wire filter mode. Take the signals to be included/excluded from an
  input wire and not from the static filter configuration

## Mod support

- [CompactCircuit](https://mods.factorio.com/mod/compaktcircuit) (filter combinators can be used in compact circuits)
- [Picker Dollies](https://mods.factorio.com/mod/PickerDollies) (filter combinators can be moved and rotated)
- [Nullius](https://mods.factorio.com/mod/nullius) support has been taken from the original filter combinator but not tested

## Functional support

- Settings copy/paste
- Entity copy/paste and blueprint support
- Entity cloning (should be compatible with Space Exploration)
- Three ticks of delay between input and output (similar to original filter combinator)

This mod started out as a collection of patches/changes to the
original filter-combinator but I started to make large scale changes
that would be difficult to take in for the original author.

This turned into a testbed to play around with ways to structure
larger mods (my first attempts were pretty unstructured and suffered
from spaghetti code syndrome). This led to the design of 'framework'
(the contents of the framework folder) which itself was heavily
inspired by flib and stdlib.

## Acknowledgements/Credits

Most code stands on the shoulders of other code and this is no
exception.

- This mod owes a great deal to Sil3ntStorm's [original filter combinator](https://mods.factorio.com/mod/silent-filter-combinator)
  While there may not be a lot of the actual code left, the basic
  structure of the internal combinator network is unchanged from the
  original filter combinator (it was always intended to be a drop-in
  replacement).

- The basic mod structure was inspired by the [stack combinator](https://mods.factorio.com/mod/stack-combinator) by modo_lv.
  I started poking around at the innards of other mods because I
  wanted to implement compact circuit support for the stack combinator
  within the code (not with an add on).

- Some of the framework code was either lifted or inspired by
  [raiguard's factorio library](https://mods.factorio.com/mod/flib).

- [Nexela's stdlib](https://mods.factorio.com/mod/stdlib) was a big
  inspiration for the event driven design. With no official release of
  stdlib for factorio 2.0 in sight, the relevant pieces are lifted here
  and patched for 2.0 compatibility.

## License/copyrights

Full code base:

Copyright (C) 2024 Henning Schmiedehausen, licensed under the [MS-RL](https://opensource.org/licenses/MS-RL) license.

The contents of the framework and the stdlib folder:

Copyright (C) 2024 Henning Schmiedehausen, licensed under the MIT license or the MS-RL license.


--------------------------------------------------

Potions of this code are:

- Copyright 2023 [Sil3ntStorm](https://github.com/Sil3ntStorm) and licensed under the [MS-RL](https://opensource.org/licenses/MS-RL)
- Copyright (c) 2020 raiguard and licensed under the MIT License
- Copyright (c) 2016, Afforess and licensed under the MIT License
