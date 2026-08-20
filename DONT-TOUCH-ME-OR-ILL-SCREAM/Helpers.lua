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

return Helpers