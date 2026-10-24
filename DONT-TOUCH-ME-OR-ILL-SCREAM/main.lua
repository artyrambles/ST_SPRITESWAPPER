return function(mod)
  mod.log:info("[ST_SPRITESWAPPER] Mod loaded and ready to process sprite packs.")

  local module_path = mod.path .. "/DONT-TOUCH-ME-OR-ILL-SCREAM/"
  local helpers = require(module_path .. "Helpers")
  local Stats = require("src.pokemon.Stats") -- needed for the recomp's native shiny pokemon detection

  local loaded_sprite_packs = {}
  local loaded_animations = {} -- structure: {speciesId = {animated file ref, loop?}, ..., ...} -- WIP!!
  local use_animations = false -- for compatibility -- WIP!
  local sprite_dimensions_w = 56 -- for compatibility -- WIP!
  local sprite_dimensions_h = 56 -- for compatibility -- WIP!
  local fallback_sprite_dimensions = 56 -- WIP!
  local anim_frame_back = 0 -- for animations, WIP!
  local anim_frame_front = 0 -- for animations, WIP!
  local anim_loop_back = false
  local anim_loop_front = false
  local default_duration = 12 -- frames for each animated cell -- WIP!
  local which_gen = 0 -- this lets the sprite swapper mod remember which gen the game that currently runs is. it gets detected in a very hack-y way during initialization.
  local gen_detected = false -- only trigger gen check once.
  local backscale_detected = false -- only trigger this check once.
  local backscale_cache = -1

  local unown_letters = {
    "A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z",  
    "!", "?"
  }
  local castform_forms = {
    "SUN", "RAIN", "HAIL" -- doesn't have a form for sandstorm, apparently. TIL lol
  }

  local pack_choices = { { "NONE", "NONE" } }

  mod.events:on("mod.options_changed", function(e)
    if e.mod.id == mod.id then
      mod.save:set("chosenpack", (mod.options:get("packchoice", "NONE")))
      mod.save:set("useshinies", (mod.options:get("useshinies", false)))
      mod.save:set("backspritescale", (mod.options:get("backspritescale", -2))) -- copypaste mishap fixed in 0.0.2 -- also fixed default/fallback value for this in 1.0.0 so it doesn't reset itself back to default constantly. also defaults to 1 now.
    end
  end)

  -- trying to alter an existing pokemon's data without making sure it's complete will cause errors. so you first gotta copy the existing data as a template.
  local function deepCopyPokemon(pid)
    local real_pokemon = mod.content.pokemon:get(pid)
    assert(real_pokemon, pid .. " is missing from the imported base pokemon data.")
    local new_pokemon = {}
    for key, value in pairs(real_pokemon) do new_pokemon[key] = value end
    return new_pokemon
  end

  for id, mon in mod.content.pokemon:each() do
    --local patched_pokemon = deepCopyPokemon(id) -- removed this in 1.1.0, since the pokemon data no longer gets copied and overriden but just patched once now. it was pointless to override anyway since changing the backsprite scale option at runtime doesn't work.
    --mod.log:info(tostring(id))
    local backscale = mod.options:get("backspritescale", -2)
    if not backscale_detected then 
      backscale_detected = true
      local Version = require("src.core.GameVersion")
      which_gen = Version.generation() -- added this new check in 1.1.0
      if not gen_detected and (which_gen == 2 or which_gen == 3) then -- alternatively could check if at any point the dex number exceeds 151 here.
        mod.log:info("Running a gen2 or gen3 game, apparently!")
      elseif not gen_detected then
        mod.log:warn("Could not detect which generation of game this is at all. Reverting to the default gen1 behavior...godspeed!")
        which_gen = 1
      --else
        --mod.log:info("[ST_SPRITESWAPPER] already checked for gen. it's gen" .. tostring(which_gen) .. ".")
      end
      gen_detected = true
      -- get the backscale and remember it. this is very janky. i know. shut up.
      if backscale == "2x" or backscale == "2" or backscale == 2 then 
        backscale_cache = 2
      elseif backscale == "-2" or backscale == -2 or backscale == "gen1 2x" then
        if which_gen == 1 then
          backscale_cache = 2
        else
          backscale_cache = 1
        end
      elseif backscale == "half" or backscale == 0.5 or backscale == "0.5" then
        backscale_cache = 0.5
      else
        backscale_cache = 1
      end
    end

    if which_gen <= 1 then -- in gen3 and gen2 the battleScaleBack seems to cause a crash under api v3, so don't apply the patch there for now
    --patched_pokemon.battleScaleBack = backscale_cache -- temporarily set all of these to 1 since we need to adjust it again after the freeze anyway -- removed this in 1.1.0
      mod.content.pokemon:patch(id, {battleScaleBack = backscale_cache})
    end
  end

  mod.events:on("mods.loaded", function(e)
    for id, rmod in pairs(e["loader"].exports) do
      mod.log:info("Looking at mod: ".. id)
      local lmod = mod.find(id)
      -- fallback for backwards compatibility with older sprite packs that don't have the true color shiny sprites setting. added in 1.0.0
      if not lmod.exports.trueColorShinySprites then lmod.exports.trueColorShinySprites = lmod.exports.trueColorSprites end
      local exp = lmod.exports
      if exp.isSpritePack then
        table.insert(loaded_sprite_packs, {mod_id = id, mod_version = lmod.version, mod_exports = exp})
        table.insert(pack_choices, {exp.packLabel, id})
        mod.log:info(id .. " was added to mod options.")
      end
      -- only now build the mod options menu from the available packs
      mod.options:define({
        { key = "packchoice", label = "SPRITE PACK", type = "choice", default = "NONE",
          choices = pack_choices },
        {key = "useshinies", label = "SHINY GEN1 PKMN?", type = "toggle", default = true},
        {key = "backspritescale", label = "(RESTART) BACKSPR.SCALE", type = "choice", default = -2, -- changed to a choice type setting, and changed to default to 1 since I assume a lot of people will use this for gen2/3 rather than 1 -- actually nevermind, changed it to "gen1 2x"
          choices = {{"1x", 1}, {"2x", 2}, {"gen1 2x", -2}, {"half", 0.5}}} -- "gen1 2x" and "half" option added in v1.0.0. removed 4x option since i can't imagine a single usecase for it.
          -- "gen1 2x": scale ONLY gen1 sprites to 2x (as is default for gen1) and all other to 1x
      })
    end
  end)

  -- change the mon's sprites when they are requested by the game's visuals
  mod.hooks:wrap("pokemon.sprite", function(next, path, ctx)
    --mod.log:info("Starting pokemon.sprite wrapped function!")
    path = next(path, ctx)
    local side = ctx.side == "back" and "back" or "front"
    --if tostring(ctx.species) == "CASTFORM" then -- was testing stuff here
    --  mod.log:info(tostring(ctx.letter))
    --   local pkmndata = mod.content.pokemon:get(ctx.species)
    --   mod.log:info(helpers.tprint(pkmndata))
    -- else
    --   mod.log:info(ctx.species)
      -- for k, v in pairs(ctx) do
      --   if k == "data" then
      --     mod.log:info(k .. tostring(table.concat(v, ", ")))
      --   else
      --     mod.log:info(k .. tostring(v))
      --   end
      -- end
    --end
    local pkmn = ctx.mon
    local shinymon = false
    if pkmn and which_gen < 2 then -- this can be nil if it's not a battler in the battle screen.
      shinymon = Stats.isShiny(pkmn.dvs) -- updated to handle gen1 as a special case
    else
      shinymon = ctx.shiny and true or false -- note to self: this now also covers gen2 shinies
    end
    -- get the mod's actual asset path
    local current_pack = mod.options:get("packchoice")
    if current_pack ~= "NONE" then
      local uletter = ""
      if tostring(ctx.species) == "UNOWN" then
        uletter = "_" .. unown_letters[ctx.letter]
      end
      local cform = ""
      if tostring(ctx.species) == "CASTFORM" then
        if tostring(ctx.form) ~= "0" then
          cform = "_" .. castform_forms[ctx.form]
        end
      end
      local lmod = mod.find(current_pack)
      if lmod then
        if lmod.exports.animatedSprites then 
          -- do this just in time because the player could have swapped sprite pack anytime
          use_animations = true
          sprite_dimensions_w = lmod.exports.spritesize_w
          sprite_dimensions_h = lmod.exports.spritesize_h
        else
          -- revert to default settings
          use_animations = false
          sprite_dimensions_w = fallback_sprite_dimensions
          sprite_dimensions_h = fallback_sprite_dimensions
        end
        -- actual sprite path gets deduced here
        if shinymon and lmod.exports.providesShinySprites and mod.options:get("useshinies", false) then
          --mod.log:info("pokemon is shiny.")
          local sprite_file = nil
          sprite_file = lmod.exports.modPath .. "/assets/pokemon/".. side .. "/shiny/".. ctx.species .. uletter .. cform .. ".png"
          local sprite_exists = helpers.imgExistsBool(sprite_file)
          ctx.trueColor = sprite_exists and lmod.exports.trueColorShinySprites
          mod.log:info("[ST_SPRITESWAPPER] Loading sprite from file: ".. sprite_file)
          return sprite_exists and sprite_file or path
        else
          local sprite_file = lmod.exports.modPath .. "/assets/pokemon/".. side .. "/normal/".. ctx.species .. uletter .. cform .. ".png"
          local sprite_exists = helpers.imgExistsBool(sprite_file)
          mod.log:info("[ST_SPRITESWAPPER] Loading sprite from file: ".. sprite_file)
          ctx.trueColor = sprite_exists and lmod.exports.trueColorSprites
          return sprite_exists and sprite_file or path
        end
      end
    else
      -- also revert to default sprite settings
      use_animations = false
      sprite_dimensions_w = fallback_sprite_dimensions
      sprite_dimensions_h = fallback_sprite_dimensions
    end
    return path
  end)

  -- new in 1.0.0: also replace the menu/party icons
  local Version = require("src.core.GameVersion")
  which_gen = Version.generation()
  if which_gen >= 0 then -- no longer necessary since it won't crash the game in gen3 anymore in api v3, remove check in next version
    mod.hooks:wrap("pokemon.icon", function(next, path, ctx)
      mod.log:info("pokemon.icon hook has fired.")
      path = next(path, ctx)
      local pkmn = ctx.mon
      local shinymon = ctx.shiny and true or false -- handles the shiny status if it came from the hook already, otherwise will check its DVs (changed in 1.2.0)
      if pkmn then -- this can be nil in certain situations, I guess
        -- local shinymon_gen3 = false -- gen3 handles shiny pokemon differently than gen2 apparently? so here comes v1.1.1 fixing the shiny check for gen3...
        -- if which_gen >= 3 then
        --   shinymon_gen3 = helpers.isShiny(pkmn)
        --   -- if shinymon_gen3 then 
        --   --   --mod.log:info("pkmn is shiny!")
        --   -- else
        --   --   --mod.log:info("pokemon isn't shiny or shiny data isn't available!")
        --   -- end
        -- end -- commented out all of this for 1.2.0 because ctx.mon isn't provided by the gen3 hook to begin with. so this code was never reached in the first place.
        shinymon = Stats.isShiny(pkmn.dvs)-- or shinymon_gen3 -- added handling for gen3 shiny pokemon here (hopefully?). -- note for 1.2.0: removed this code again for reasons stated above
      end
      -- get the mod's actual asset path
      local current_pack = mod.options:get("packchoice")
      if current_pack ~= "NONE" then
        local lmod = mod.find(current_pack)
        if lmod then
          -- actual sprite path gets deduced here
          if shinymon and lmod.exports.providesShinySprites and mod.options:get("useshinies", false) then
            --mod.log:info("pokemon is shiny.")
            local sprite_file = nil
            sprite_file = lmod.exports.modPath .. "/assets/pokemon/icons/shiny/".. ctx.species .. ".png"
            local sprite_exists = helpers.imgExistsBool(sprite_file)
            ctx.trueColor = sprite_exists and lmod.exports.trueColorShinySprites
            --mod.log:info("[ST_SPRITESWAPPER] Loading icon from file: ".. sprite_file)
            return sprite_exists and sprite_file or path
          end
          local sprite_file = lmod.exports.modPath .. "/assets/pokemon/icons/normal/".. ctx.species .. ".png"
          local sprite_exists = helpers.imgExistsBool(sprite_file)
          --mod.log:info("[ST_SPRITESWAPPER] Loading icon from file: ".. sprite_file)
          ctx.trueColor = sprite_exists and lmod.exports.trueColorSprites
          return sprite_exists and sprite_file or path
        end
      end
      return path
    end)
  end

  -- drafting up stuff for next version of the mod
  -- for reference, this would be the way to replace a overworld walk sprite
  -- local swap_file = mod.path .. "/assets/trainer/" .. "kris.png"
  -- mod.content.sprites:patch("SPRITE_RED", { image = swap_file, frames = 6 })

  -- mod.hooks:wrap("player.sprite", function(next, path, ctx)
  --   path = next(path, ctx)
  --   if ctx.demo then return path end          -- leave the old man alone
  --   local outfit = mod.save:get("outfit")
  --   if not outfit then return path end
  --   return mod.assets:path(("art/%s_%s.png"):format(outfit, ctx.side))
  -- end)
end