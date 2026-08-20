return function(mod)
  mod.log:info("[ST_SPRITESWAPPER] Mod loaded and ready to process sprite packs.")

  local module_path = mod.path .. "/DONT-TOUCH-ME-OR-ILL-SCREAM/"
  local helpers = require(module_path .. "Helpers")
  local Stats = require("src.pokemon.Stats") -- needed for the recomp's native shiny pokemon detection

  local loaded_sprite_packs = {}
  local loaded_animations = {} -- structure: {speciesId = animated file ref, ..., ...}
  local use_animations = false -- for compatibility
  local sprite_dimensions_w = 56 -- for compatibility
  local sprite_dimensions_h = 56 -- for compatibility
  local fallback_sprite_dimensions = 56
  local default_duration = 12 -- frames for each animated cell

  local pack_choices = { { "NONE", "NONE" } }

  mod.events:on("mod.options_changed", function(e)
    if e.mod.id == mod.id then
      mod.save:set("chosenpack", (mod.options:get("packchoice", "NONE")))
      mod.save:set("useshinies", (mod.options:get("useshinies", false)))
      mod.save:set("backspritescale", 2) -- copypaste mishap fixed in 0.0.2
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

  mod.hooks:wrap("core.update", function(next, game, dt)
    for id, animation in pairs(loaded_animations) do
      animation.currentTime = animation.currentTime + dt
      if animation.currentTime >= animation.duration then
          animation.currentTime = animation.currentTime - animation.duration
      end
      local spriteNum = math.floor(animation.currentTime / animation.duration * #animation.quads) + 1
      love.graphics.draw(animation.spriteSheet, animation.quads[spriteNum], 0, 0, 0, 4)
    end
    return next(game, dt)
  end)

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
      shinymon = Stats.isShiny(pkmn.dvs)
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
          ctx.trueColor = sprite_exists --and lmod.exports.trueColorSprites
          --mod.log:info("[ST_SPRITESWAPPER] Loading sprite from file: ".. sprite_file)
          return sprite_exists and sprite_file or path
        end
        local sprite_file = nil
        local animation = loaded_animations[ctx.species]
        if use_animations and animation then
          --local spriteNum = math.floor(animation.currentTime / animation.duration * #animation.quads) + 1
          sprite_file = animation.spriteSheet
        elseif use_animations then 
          -- first try creating the animation
          local cell_path = "_0"
          local anim_path = lmod.exports.modPath .. "/assets/pokemon/".. side .. "/normal-animated/".. ctx.species .. cell_path .. ".png"
          local new_anim = helpers.newAnimation(anim_path, sprite_dimensions_w, sprite_dimensions_h, default_duration)
          if new_anim then
            table.insert(loaded_animations, ctx.species = new_anim)
          else
            -- animation still couldn't be loaded, fall back to default sprite.
            mod.log:warn("[ST_SPRITESWAPPER] No animated spritesheet found for ".. ctx.species .."! Falling back to default sprite.")
          end
        else
          -- normal, static sprite
          sprite_file = lmod.exports.modPath .. "/assets/pokemon/".. side .. "/normal/".. ctx.species .. ".png"
        end
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

  -- mod.hooks:wrap("pokemon.icon", function(next, path, ctx)
  --   path = next(path, ctx)
  --   local skin = ctx.mon and ctx.mon.skin
  --   if not skin then return path end
  --   return mod.assets:path(("icons/%s.png"):format(ctx.species, skin))
  -- end)

  -- for reference, this would be the way to replace a overworld walk sprite
  --mod.content.sprites:register("SPRITE_HERO", { image = swap_file, frames = 6 })

end