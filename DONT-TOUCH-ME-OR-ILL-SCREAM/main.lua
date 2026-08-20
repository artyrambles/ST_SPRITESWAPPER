return function(mod)
  mod.log:info("[ST_SPRITESWAPPER] Mod loaded and ready to process sprite packs.")

  local module_path = mod.path .. "/DONT-TOUCH-ME-OR-ILL-SCREAM/"
  local helpers = require(module_path .. "Helpers")
  local Stats = require("src.pokemon.Stats") -- needed for the recomp's native shiny pokemon detection

  local loaded_sprite_packs = {}

  local pack_choices = { { "NONE", "NONE" } }

  mod.events:on("mod.options_changed", function(e)
    if e.mod.id == mod.id then
      mod.save:set("chosenpack", (mod.options:get("packchoice", "NONE")))
      mod.save:set("useshinies", (mod.options:get("useshinies", false)))
      mod.save:set("useshinies", 2)
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
    patched_pokemon.battleScaleBack = mod.options:get("backspritescale", 2)
    --patched_pokemon.battleScaleBack = 1
    mod.content.pokemon:override(id, patched_pokemon)
  end

  mod.events:on("mods.loaded", function(e)
    for id, rmod in pairs(e["loader"].exports) do
      mod.log:info("[ST_SPRITESWAPPER] Looking at mod: ".. id)
      local lmod = mod.find(id)
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
          {key = "useshinies", label = "SHINY POKEMON?", type = "toggle", default = true},
          {key = "backspritescale", label = "BACKSPR.SCALE (RESTART)", type = "number", default = 2,
          choices = {{"1x", 1}, {"2x", 2}, {"4x", 4}}}
      })
    end
  end)

  -- store the player's pick on the mon somehow (mod.save, a link_fields
  -- bag field, nickname tag, …); this example reads mon.skin
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
      shinymon = Stats.isShiny(pkmn.dvs)
    end
    -- get the mod's actual asset path
    local current_pack = mod.options:get("packchoice")
    if current_pack ~= "NONE" then
      local lmod = mod.find(current_pack)
      if lmod then
        if shinymon and lmod.exports.providesShinySprites and mod.options:get("useshinies", false) then
          mod.log:info("pokemon is shiny.")
          local sprite_file = lmod.exports.modPath .. "/assets/pokemon/".. side .. "/shiny/".. ctx.species .. ".png"
          local sprite_exists = helpers.imgExistsBool(sprite_file)
          ctx.trueColor = sprite_exists --and lmod.exports.trueColorSprites
          --mod.log:info("[ST_SPRITESWAPPER] Loading sprite from file: ".. sprite_file)
          return sprite_exists and sprite_file or path
        end
        local sprite_file = lmod.exports.modPath .. "/assets/pokemon/".. side .. "/normal/".. ctx.species .. ".png"
        local sprite_exists = helpers.imgExistsBool(sprite_file)
        --mod.log:info("[ST_SPRITESWAPPER] Loading sprite from file: ".. sprite_file)
        ctx.trueColor = sprite_exists and lmod.exports.trueColorSprites
        return sprite_exists and sprite_file or path
      end
    end
    return path
  end)

  -- mod.hooks:wrap("pokemon.icon", function(next, path, ctx)
  --   path = next(path, ctx)
  --   local skin = ctx.mon and ctx.mon.skin
  --   if not skin then return path end
  --   return mod.assets:path(("icons/%s.png"):format(ctx.species, skin))
  -- end)

  -- for reference, this would be the way to replace a overworld walk sprite
  --mod.content.sprites:register("SPRITE_HERO", { image = swap_file, frames = 6 })

end