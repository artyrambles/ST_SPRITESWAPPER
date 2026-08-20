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

return Helpers