local function copy_table(obj, seen)

  if type(obj) ~= 'table' then
    return obj 
  end

  if seen and seen[obj] then 
    return seen[obj] 
  end

  local s = seen or {}
  local res = {}
  
  s[obj] = res
  
  for k, v in pairs(obj) do 
    res[copy_table(k, s)] = copy_table(v, s)
  end
  
  return setmetatable(res, getmetatable(obj))

end

local function log(method, message)

  local logfile_path = "nz_debug.log"

  if (method == nil) then method = 'UNKNOWN' end

  if (message ~= nil) then
  
    local h = math.floor(game.ticks_played / 60 / 60 / 60)
    local m = math.floor(game.ticks_played / 60 / 60  - 60 * h)
    local s = math.floor(game.ticks_played / 60 - 60 * 60 * h - 60 * m)

    messagebody = string.format("%03d:%02d:%2d", h, m, s) ..  ' | ' .. method .. ' | ' .. message
    game.write_file(logfile_path, messagebody .. '\n', true)
  end
end

local function dump(o)
--  log('dump', 'dumping a object of type of ' .. type(o))
  if (type(o) == 'table') or (type(0) == 'userdata') then
     local s = '{ '
     for k,v in pairs(o) do
        if type(k) ~= 'number' then k = '"'..k..'"' end
        s = s .. '['..k..'] = ' .. dump(v) .. ','
     end
     return s .. '} '
  else
     return tostring(o)
  end
end

--[[ Take argument of array, separator (optional), and fieldname (optional)]]
local function array_to_string(arg)

  local result = nil
  local separator = arg.separator

  if (separator == nil) then 
    separator = ',' 
  end

  for _, v in ipairs(arg.array)
  do
    local val

    if (arg.fieldname == nil) then
      val = v
    else
      val = v[arg.fieldname]
    end

    if (result == nil) then
      result = val
    else
      result = result .. separator .. ' ' .. val
    end
  end

  return result  
end

local function get_surface()
  return game.get_surface('nauvis')
end

local function get_production_rate(area_number)

  local surface = get_surface()
  local scriptarea = surface.get_script_area(area_number)
  log('main', 'The area to script is:' .. dump(scriptarea))

  local count = 0

  local entitylist = surface.find_entities_filtered{area=scriptarea.area, force="player"}

  for _, entity in ipairs(entitylist)
  do
    log('Main',"Found entity " .. entity.name .. " type " .. entity.type .. " count " .. count )
    count = count + 1

    if entity.type == 'furnace' then
      log('Main', 'furace at ' .. dump(entity.bounding_box) .. ' products finished: ' .. ( entity.products_finished or 0) )
    end
  end
end

get_production_rate(4)