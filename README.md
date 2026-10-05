<img width="678" height="92" alt="banner" src="https://github.com/user-attachments/assets/2eaf8621-e104-4ead-98e5-7e8e01a24ce9" />

This mod is meant to be installed alongside any number of compatible Sprite Pack mods and lets the player choose which of the installed Sprite Pack mods to use from the mod's options menu.

## Features
- Detects installed compatible Sprite Pack mods and adds them as an entry to its mod options menu.
- Can change the scale of the backsprites (restart required to apply the setting).
- Works with gen1, gen2, and gen3.
- Sprite Pack mods can supply either full color or palette-based sprites. (gen3 only supports full color!)
- Static front and back sprites are supported, as well as animated party menu icons.
- DV-based shinies are supported for gen1 (if provided by the Sprite Pack), with an mod options toggle to disable them if that is not wanted.
- Sprite-swapping DV- and IV-based shinies is supported for gen2 and gen3.
- Custom species added through mods are supported, though it is experimental
- If a sprite isn't provided by the Sprite Pack mod, the normal ("vanilla") sprite will be used for that Pokemon.
- Players can rescale backsprites with a handy mod setting that can rescale all of them or leave gen1 alone, which solves the problem of backsprites having different scales across gens.

## Creating Sprite Pack Mods
An example Sprite Pack Mod can be found in the releases tab. It was made to be as easy to customize as possible, needing basically no coding knowledge. Its included guide describes exactly what changes need to be made to the included Config and manifest files in order to customize the Sprite Pack mod.

Then, the sprite image files can be added by simply naming them after their species (in CAPSLOCK), as png files, going into their respective folders.
After rezipping the customized Sprite Pack mod, it can be distributed and installed like any other mod.

Check [this guide](SPRITE_PACK_GUIDE.md) for more in-depth info and notes about how to create and customize Sprite Packs. An up-to-date version of that guide is included in the example sprite pack zip.
