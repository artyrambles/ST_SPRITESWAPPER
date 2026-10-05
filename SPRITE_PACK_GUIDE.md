# HOW TO CUSTOMIZE SPRITE PACKS
An up-to-date version of this guide is always included with the Example Sprite Pack that can be found on the Releases page of the github repo of the SPRITE SWAPPER mod.

1. Unzip the template and look at the assets folder. There are example sprites for the gen1 starters included.
2. Place your Pokemon sprites in the respective folders. Make sure they are all named like their Pokemon species name as it appears in-game, in English, all-caps. There are some small differences so if you're unsure or run into issues, try the filename remapping options in the Config file. (!!THAT FEATURE DOES NOT WORK YET!!)
3. Open the manifest.json with any plain text editor and change the following fields inside it to your liking:
  - id. Ideally, there should be no special characters or spaces in this id, as it will be referenced by code.
  - name. This will be displayed as your mod's name in the launcher, for example.
  - description. This will also be displayed in the launcher.
  - version. If you want to change this, you can.
  - games. If you only want your Sprite Pack to be available for certain gens, remove the entries for the other ones from that list. the square brackets must remain intact!
  - Don't change anything else in there!
4. Open the Config.lua file with a plain text or code editor. It contains an editable section with explanations on what the config options mean.
   Changing the value of optionsLabel at the very least is recommended. Most other options can be left alone as they already have useful default values.
5. Do not open or change the main.lua file in any way. It reads all your custom info from the Config.lua so there's nothing in there you need to edit, ever.
  - However, if you are updating to a newer Sprite Pack template for some reason, you should overwrite the main.lua with the updated new version at least.
6. Zip up the folder of your mod, name it whatever you like, and test it by installing it in your launcher. It won't work if you don't also install ST_SPRITESWAPPER.
  - Make sure the zip directly contains the files in this folder, and they aren't nested inside another folder that has the name of your mod. Recomp can't read mod manifest files that are "hidden"
    inside another folder inside the zip.
7. If it works, share it with people! If it doesn't work, make sure you have installed ST_SPRITESWAPPER, you have selected this sprite pack in SPRITE SWAPPER's mod
   options, and that you have provided all the necessary sprites. Any sprite you don't include will appear as its vanilla self. Ensure also that your edits to the Config.lua
   and manifest.json didn't break these files. They require a certain syntax to work, and making changes to them wrong will break their correct formatting that they need to work.
   - If all of these things appear to be correct, double-check that you didn't make any typoes in the filenames.
   - Only use png files for the sprites! Any other file format, including jpg, jpeg, webp, gif, etc, files will NOT work.

## SOME EXTRA NOTES AND INFO

### Cross-Gen Differences and Oddities
Fist of all, I strongly recommend against trying to make your sprite pack compatible with all gens at once. That way lies madness, and there are (currently, at least)
some hard incompatibilities in the way the graphics need to be set up for them to work on each gen.
But if you're just trying to choose which gen(s) to make a sprite pack for, here's a few things to keep in mind, if they haven't been mentioned in other places of this mod's guides yet.

#### Front and Back Sprites are (almost) straightforward
-  Gen1 and Gen2 games can use greyscale sprites which then have their respective palette applied to color them in automatically, but that is probably
   not what most people are looking to do. So if you're not retro-minded, make sure to keep the trueColorSprites Config option `true`.
   Gen3 games don't do palettes, at least not in the recomp, so you will always want to use truecolor sprites in those, and in fact the trueColorSprites config option is ignored by recomp for those.
- Gen1 and Gen2 sprites, when using palette colors (so, trueColorSprites is `false`), need to be in greyscale and have specific shades of colors. They need to be pixel perfect too, if you have
   artifacts or smudged colors, there is no telling what exactly will happen but I can at least guarantee you it won't look the way you wanted it to look.
   Gen1 front and back sprites use pure white (#FFFFFF), light grey (#AAAAAA), dark grey (#555555), and pure black (#000000). It HAS to be these exact four colors, and there must be all 4 of them.
   Gen2 front and back sprites use the same greyscale colors, but since the palettes that get applied to the sprite are different between Gen1 and Gen2, some Gen1 sprites if used with a Gen2 game
   will look very bad.
- The dimensions of the sprites seem to be the same across all three gens. The front and back sprites are 56x56 pixels. 
- In gen1 only, the back sprites are scaled up 2x. There is a setting in the SPRITE SWAPPER mod for players to set their preferred backsprite scaling, and it makes an exception for gen1 backsprites
   if they set it to "gen1 2x". That way you don't need to worry about changing your pack's backsprite scale to match or not match gen1 backsprites. Going with 1x scale should work fine even when you
   make sprite packs for gen1, as players can simply change the scaling to be 1x across all gens they want to play.
- In gen3, the front sprites seem to be cropped to be more in the middle of the 56x56 pixel canvas when they don't fill out the whole canvas. Keep this in mind when you create front sprites of
   small Pokemon for gen3 sprite packs. Try to leave a little empty space below their feet or they will awkwardly hide partially behind the HP bars while in combat.
- Normally, gen1 doesn't have shiny Pokemon graphics, but since the invisible stats that decide whether a Pokemon is shiny or not are the same in gen1 and gen2, the SPRITE SWAPPER has shiny Pokemon
   support for gen1 built-in. If you can't see shiny sprites in gen1 or gen2, make sure you have changed providesShinySprites to `true` in the Config and that the SPRITE SWAPPER's option 
   "SHINY GEN1 PKMN?" is set to `ON` inside the game.
   Keep in mind that gen1 doesn't have any built-in shiny palettes, so if you change trueColorShinySprites to `false` in your Config, they won't look the way you probably thought they would.

#### Icons are kind of weird, unfortunately.
- In gen1 games, the icons are just their left half, mirrored. If your icon isn't perfectly symmetrical, it will turn into an ink blot test.
- In gen2 games, the icons MUST be greyscale or they will have unpredictable colors. The greyscale color values must also match the ones in the example icon graphic I provided. There can only 
   be two shades of grey and the black outlines, so a total of 3 colors: light grey (#AAAAAA), darker grey (#555555), and pure black (#000000).
- In gen3 games, the icon replacements currently do not work at all as of gen1recomp version 0.3.52 but I have submitted an issue report on github so it should be fixed soon.
   Either way, they are truecolor just like the front and back sprites, so greyscale graphics stay grayscale here.