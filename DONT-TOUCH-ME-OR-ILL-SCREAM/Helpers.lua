local Helpers = {}

-- check if file exists. helper function
function Helpers.imgExists(filename, og_filename)
  do
    local ok
    ok = pcall(love.graphics.newImage, filename)
    if not ok then filename = og_filename end
  end
  return filename
end

function Helpers.imgExistsBool(filename)
  local ok
  do
    ok = pcall(love.graphics.newImage, filename)
  end
  return ok
end

function Helpers.tableContains(table, element)
  for _, value in pairs(table) do
    if value == element then
      return true
    end
  end
  return false
end

-- function taken from love2d's animated sprite tutorial
function Helpers.newAnimation(image, width, height, duration)
  local animation = {}
  animation.spriteSheet = image;
  animation.quads = {};

  for y = 0, image:getHeight() - height, height do
    for x = 0, image:getWidth() - width, width do
      table.insert(animation.quads, love.graphics.newQuad(x, y, width, height, image:getDimensions()))
    end
  end

  animation.duration = duration or 1
  animation.currentTime = 0

  return animation
end

-- this is just a copy of the gen3 shiny check based onh the PID. currently not used for anything but pasting it here for reference
function Helpers.isShiny(mon)
  if type(mon) ~= "table" then return false end
  if mon.isShiny ~= nil then return mon.isShiny and true or false end
  local p = (tonumber(mon.personality) or 0) % 0x100000000
  local tid = (tonumber(mon.otId or mon.trainerId) or 0) % 0x10000
  local sid = (tonumber(mon.otSecretId) or 0) % 0x10000
  local v = bit.bxor(bit.bxor(tid, sid), bit.bxor(math.floor(p / 0x10000), p % 0x10000))
  return v < 8
end

-- this recursively prints all entries of a table (that can contain tables) in a JSON-like format. for debugging. careful about possible infinite loops.
-- function was written by Luiz Menezes: https://stackoverflow.com/a/41943392
function tprint (tbl, indent)
  if not indent then indent = 0 end
  local toprint = string.rep(" ", indent) .. "{\r\n"
  indent = indent + 2 
  for k, v in pairs(tbl) do
    toprint = toprint .. string.rep(" ", indent)
    if (type(k) == "number") then
      toprint = toprint .. "[" .. k .. "] = "
    elseif (type(k) == "string") then
      toprint = toprint  .. k ..  "= "   
    end
    if (type(v) == "number") then
      toprint = toprint .. v .. ",\r\n"
    elseif (type(v) == "string") then
      toprint = toprint .. "\"" .. v .. "\",\r\n"
    elseif (type(v) == "table") then
      toprint = toprint .. tprint(v, indent + 2) .. ",\r\n"
    else
      toprint = toprint .. "\"" .. tostring(v) .. "\",\r\n"
    end
  end
  toprint = toprint .. string.rep(" ", indent-2) .. "}"
  return toprint
end

Helpers.tprint = tprint

return Helpers