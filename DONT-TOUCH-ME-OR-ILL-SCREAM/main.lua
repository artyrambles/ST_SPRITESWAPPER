return function(mod)
  mod.log:info("[ST_SPRITESWAPPER] Mod loaded and ready to process sprite packs.")

  local module_path = mod.path .. "/DONT-TOUCH-ME-OR-ILL-SCREAM/"
  local helpers = require(module_path .. "Helpers")
  local Stats = require("src.pokemon.Stats") -- needed for the recomp's native shiny pokemon detection

  local loaded_sprite_packs = {}
  local loaded_animations = {} -- structure: {speciesId = animated file ref, ..., ...} -- WIP!!
  local use_animations = false -- for compatibility -- WIP!
  local sprite_dimensions_w = 56 -- for compatibility -- WIP!
  local sprite_dimensions_h = 56 -- for compatibility -- WIP!
  local fallback_sprite_dimensions = 56 -- WIP!
  local default_duration = 12 -- frames for each animated cell -- WIP!
  local which_gen = 1 -- this lets the sprite swapper mod remember which gen the game that currently runs is. it gets detected in a very hack-y way during initialization.
  local gen_detected = false -- only trigger gen check once.
  local backscale_detected = false -- only trigger this check once.
  local backscale_cache = 1

  local pack_choices = { { "NONE", "NONE" } }

  mod.events:on("mod.options_changed", function(e)
    if e.mod.id == mod.id then
      mod.save:set("chosenpack", (mod.options:get("packchoice", "NONE")))
      mod.save:set("useshinies", (mod.options:get("useshinies", false)))
      mod.save:set("backspritescale", (mod.options:get("backspritescale", 1))) -- copypaste mishap fixed in 0.0.2 -- also fixed default/fallback value for this in 1.0.0 so it doesn't reset itself back to default constantly. also defaults to 1 now.
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
    local patched_pokemon = deepCopyPokemon(id)
    local backscale = mod.options:get("backspritescale", 1)
    if not backscale_detected then 
      backscale_detected = true
      if not gen_detected and patched_pokemon.levelMoves then -- alternatively could check if at any point the dex number exceeds 151 here.
        mod.log:info("[ST_SPRITESWAPPER] running a gen2 or gen3 game, apparently!")
        which_gen = 2 -- also could be gen3 but the difference doesn't matter here.
      elseif not gen_detected then
        mod.log:info("[ST_SPRITESWAPPER] running a gen1 game, apparently!")
        which_gen = 1
      else
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

    patched_pokemon.battleScaleBack = backscale_cache -- temporarily set all of these to 1 since we need to adjust it again after the freeze anyway
    mod.content.pokemon:override(id, patched_pokemon)
  end

  mod.events:on("mods.loaded", function(e)
    for id, rmod in pairs(e["loader"].exports) do
      mod.log:info("[ST_SPRITESWAPPER] Looking at mod: ".. id)
      local lmod = mod.find(id)
      -- fallback for backwards compatibility with older sprite packs that don't have the true color shiny sprites setting. added in 1.0.0
      if not lmod.exports.trueColorShinySprites then lmod.exports.trueColorShinySprites = lmod.exports.trueColorSprites end
      local exp = lmod.exports
      if exp.isSpritePack then
        table.insert(loaded_sprite_packs, {mod_id = id, mod_version = lmod.version, mod_exports = exp})
        table.insert(pack_choices, {exp.packLabel, id})
        mod.log:info("[ST_SPRITESWAPPER] ".. id .. " was added to mod options.")
      end
      -- only now build the mod options menu from the available packs
      mod.options:define({
        { key = "packchoice", label = "SPRITE PACK", type = "choice", default = "NONE",
          choices = pack_choices },
        {key = "useshinies", label = "SHINY GEN1 PKMN?", type = "toggle", default = true},
        {key = "backspritescale", label = "(RESTART) BACKSPR.SCALE", type = "choice", default = 1, -- changed to a choice type setting, and changed to default to 1 since I assume a lot of people will use this for gen2/3 rather than 1
          choices = {{"1x", 1}, {"2x", 2}, {"gen1 2x", -2}, {"half", 0.5}}} -- "gen1 2x" and "half" option added in v1.0.0. removed 4x option since i can't imagine a single usecase for it.
          -- "gen1 2x": scale ONLY gen1 sprites to 2x (as is default for gen1) and all other to 1x
      })
    end
  end)

  -- change the mon's sprites when they are requested by the game's visuals
  mod.hooks:wrap("pokemon.sprite", function(next, path, ctx)
    path = next(path, ctx)
    local side = ctx.side == "back" and "back" or "front"
    -- for k, v in pairs(ctx) do
    --   if k == "montable" then
    --     mod.log:info(k .. tostring(table.concat(v, ", ")))
    --   else
    --     mod.log:info(k .. tostring(v))
    --   end
    -- end
    --local pkmn = mod.content.pokemon:get(ctx.species)
    local pkmn = ctx.mon
    local shinymon = false
    if pkmn then -- this can be nil if it's not a battler in the battle screen.
      shinymon = Stats.isShiny(pkmn.dvs) or ctx.shiny -- added handling for gen3 shiny pokemon here (hopefully?).
    end
    -- get the mod's actual asset path
    local current_pack = mod.options:get("packchoice")
    if current_pack ~= "NONE" then
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
          sprite_file = lmod.exports.modPath .. "/assets/pokemon/".. side .. "/shiny/".. ctx.species .. ".png"
          local sprite_exists = helpers.imgExistsBool(sprite_file)
          ctx.trueColor = sprite_exists and lmod.exports.trueColorShinySprites
          --mod.log:info("[ST_SPRITESWAPPER] Loading sprite from file: ".. sprite_file)
          return sprite_exists and sprite_file or path
        end
        local sprite_file = lmod.exports.modPath .. "/assets/pokemon/".. side .. "/normal/".. ctx.species .. ".png"
        local sprite_exists = helpers.imgExistsBool(sprite_file)
        --mod.log:info("[ST_SPRITESWAPPER] Loading sprite from file: ".. sprite_file)
        ctx.trueColor = sprite_exists and lmod.exports.trueColorSprites
        return sprite_exists and sprite_file or path
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
  mod.hooks:wrap("pokemon.icon", function(next, path, ctx)
    --mod.log:info("pokemon.icon hook has fired.")
    path = next(path, ctx)
    local pkmn = ctx.mon
    local shinymon = false
    if pkmn then -- this can be nil in certain situations, I guess
      shinymon = Stats.isShiny(pkmn.dvs) or ctx.shiny -- added handling for gen3 shiny pokemon here (hopefully?).
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

  -- for reference, this would be the way to replace a overworld walk sprite
  --mod.content.sprites:register("SPRITE_HERO", { image = swap_file, frames = 6 })
end