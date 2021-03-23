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

local function print_report(message)

  local report_file_path = "train_stop_report.txt"

  if (message ~= nil) then
  

    messagebody =  message
    game.write_file(report_file_path, messagebody .. '\n', true)

  end

end

local function debug_log(method, message)

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

local function get_surface()
  return game.get_surface('nauvis')
end


local function string_starts(String,Start)
  return string.sub(String,1,string.len(Start))==Start
end

local function format_station_key(station_name, dup_index)

  return string.format('%s[%02d]', station_name, dup_index)
end

local function create_unique_station_key(station_list, station_name)
  
  local dup_index = 0
  
  while (station_list[format_station_key(station_name, dup_index)] ~= nil) do
    dup_index = dup_index + 1
  end

  return format_station_key(station_name, dup_index)

end


local function get_train_stations(filter_function)

  local surface = get_surface()

    trainstops = {}
  name_index = {}
    for _, trainstop in pairs(surface.find_entities_filtered{name="train-stop", force = "player"}) do
        -- table.insert(trainstops, trainstop.backer_name)
    if (filter_function == nil) or filter_function(trainstop.backer_name) then
      local station_key = create_unique_station_key(trainstops, trainstop.backer_name)
      trainstops[station_key] = trainstop
      table.insert(name_index, station_key)
    end
    end
  -- debug_log('get_train_stations', serpent.block(trainstops))
  table.sort(name_index)

  return name_index, trainstops
end

local function train_station_to_string(station)

  local controllerb = station.get_control_behavior()

  local disabled = false

  if (controllerb ~= nil) then disabled = controllerb.disabled end

  local result = '{backer_name=' .. station.backer_name .. ', ' ..
  'trains_limit=' .. station.trains_limit .. ', ' ..
  'disabled=' .. tostring(disabled)
  result = result .. '}'

  return result

end

local function list_stations(filter_function)

  indexs, stations = get_train_stations(filter_function)

  -- debug_log('list_stations', serpent.block(stations))

  if (stations ~= nil) then
    local report =  string.format(
      '%-30s, %5s, %5s', 'backer_name', 'limit', 'enabled')

    for _, station_key in ipairs(indexs)
    do
      local station = stations[station_key]
      local controllerb = station.get_control_behavior()
      local disabled = false
      if (controllerb ~= nil) then disabled = controllerb.disabled end

      local trans_limit = station.trains_limit

      if trans_limit == 4294967295 then trans_limit = 99999 end
      
      report = report .. string.format(
      '\n%-30s, %5d, %5s', station_key, trans_limit, tostring(not disabled))

      local networks = station.get_circuit_network(
        defines.wire_type.red)

      debug_log('list_stations', 'circuit network for station ' .. station_key .. ' ' .. serpent.block(networks) )

    end
    
    print_report(report)

  end


end


-- list_stations(
--   function(name) 
--     -- debug_log('list_station-ana', 'for name "' .. name .. '" string.find result: ' .. tostring(string.find(name, 'lobby')))
--     return string_starts(name, 'n') and string.find(name, 'lobby') == nil
--   end
-- )


-- -- Find the stations related to copper 
-- list_stations(
--   function(name) 
--     return string_starts(name, 'n') and (string.find(name, 'core') ~= nil or string.find(name, 'copper') ~= nil)
--   end
-- )

-- Find the stations related to iron 
list_stations(
  function(name) 
    return string_starts(name, 'n') and (string.find(name, 'iore') ~= nil or string.find(name, 'iron') ~= nil)
  end
)