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

local function get_train_by_stations(stations)

  local surface = get_surface()
  local trains = surface.get_trains()

  if (stations == nil) then
    -- debug_log('get_train_by_stations', 'Check for trains with empty station list. Returning all trains')
    return trains

  else 

    debug_log('get_train_by_stations', 'Check for trains with station list starts with: ' .. array_to_string{array=stations})
    local filteredtrainlist = {}

    for trainkey, train in ipairs(trains) 
    do
      local schedule = train.schedule

      if (schedule ~= nil) and (#schedule.records > 0) then

        local isamatch = true

        for i, v in ipairs(stations) do
          if schedule.records[i].station ~= v then
            isamatch = false
            break
          end
        end

        if isamatch then
          filteredtrainlist[#filteredtrainlist+1] = train
        end
      end
    end

    return filteredtrainlist
  
  end

end

local function get_train_by_id(train_id)

  all_trains = get_train_by_stations(nil)

  train_id_number = tonumber(train_id)

  for _, train in ipairs(all_trains) do
    if (train.id == train_id_number) then
      return train
    end
  end

  return nil

end

local function get_signal_type(signal)

  if (signal == nil) then
    return ''
  else
    return '(' .. signal.type .. ')' .. signal.name
  end

end

local function get_train_station_list(train)

  local schedule = train.schedule

  if (schedule ~= nil) and (schedule.records ~= nil) then
    local result = ''
    
    for _, stop in pairs(schedule.records) do
      -- result = result .. stop.station 
      local conditions = stop.wait_conditions
      
      local condition_string = ''

      if (conditions ~= nil) then
        for _, wc in pairs(conditions) do

          if condition_string ~= nil and condition_string ~= '' then
            condition_string = condition_string .. ' ' .. string.upper(wc.compare_type) .. ' '
          end

          local wc_string = '[' .. wc.type .. ']'

          if wc.type == 'inactivity' then
            wc_string = wc_string .. ' ticks=' .. tostring(wc.ticks)
          else
            if wc.condition ~= nil then
            
              -- debug_log('get_train_station_list', serpent.block(wc.condition))

              wc_string = wc_string .. ' ' .. 
              get_signal_type(wc.condition.first_signal) ..
              tostring(wc.condition.comparator) ..
              get_signal_type(wc.condition.second_signal) ..
              tostring(wc.condition.constant)
            end
          end
          
          condition_string = condition_string .. wc_string

        end
      end 
      
      -- if result == nil then result = '\n' else result = result .. ',\n' end
      if result ~= '' then result = result .. ',\n' end
      result = result ..
      string.format('    %-20s {%s}', stop.station .. ':', condition_string)
      -- local stationlist = array_to_string{array=schedule.records, fieldname='station'}  

    end

    return result
  else
    return nil
  end
end

local function strtrain(train)
  
  
  local station_list = get_train_station_list(train)
  
  local train_string = '{train id=' .. train.id .. 
  ', manual mode=' .. tostring(train.manual_mode) .. 
  ', schedule={\n' .. station_list .. '},\n'

  local carriages = train.cargo_wagons

  local wagon_string = ''

  for i, car in pairs(carriages) do

    if wagon_string ~= '' then
      wagon_string = wagon_string .. ',\n'
    end
    
    wagon_string = wagon_string .. '  {wagon num=' .. i .. ', filter='

    local filter_string = nil

    local car_inventory = car.get_inventory(defines.inventory.cargo_wagon)
    if car_inventory ~= nil then
      for j = 1, #car_inventory do
        filter = car_inventory.get_filter(j)
        local filterdisplay = filter or ''
        if (filter_string == nil) then
          filter_string = filterdisplay
        else
          filter_string = filter_string .. ',' .. filterdisplay
        end
      end
    end

    wagon_string = wagon_string .. (filter_string or '') .. '}'
  end
  train_string = train_string .. wagon_string .. '}'

  return train_string

end

local function trains_to_string(trains)

  -- debug_log('trains_to_string', "to_string " .. #trains .. " train(s)")
  
  if #trains > 1 then

    local result

    for _, train in ipairs(trains)
    do

      --[[debug_log("About to log detail of train #" .. train.id)]]
      if (result == nil) then
        result =   'trains: {count=' .. #trains
      end

      result = result .. ',\n' .. strtrain(train)
      -- debug_log('log_trains', 'train id: ' .. train.id .. ' schedule: ' .. station_list)
    end
    return result
  else
    -- only 1 trains to string
    local result = strtrain(trains[1])
    return result
  end


end

local function update_train_schedule(template_schedule, train_to_update, commitupdate)

  local copy_of_schedule = copy_table(template_schedule)

  local current_stop = train_to_update.schedule.current

  copy_of_schedule.current = current_stop
  
  if (commitupdate) then
    debug_log('main', 'COMMIT mode. Updating train ' .. train_to_update.id .. ' to new schedule with stop id of ' .. current_stop)
    train_to_update.schedule = copy_of_schedule
  else
    debug_log('main', 'LIST mode. Not updating train ' .. train_to_update.id .. ' to new schedule with stop id of ' .. current_stop)
  end

  return train_to_update

end

local function update_train_filter(template_train, train_to_update, commitupdate)

  local template_carriages = template_train.cargo_wagons

  for carnum, template_car in pairs(template_carriages) do

    local template_car_inventory = template_car.get_inventory(defines.inventory.cargo_wagon)
    
    -- Update the car/wagon with the same number as the one that we got from template train
    local target_car = train_to_update.cargo_wagons[carnum]
    local target_car_inventory = target_car.get_inventory(defines.inventory.cargo_wagon)

    if template_car_inventory ~= nil then
      for j = 1, #template_car_inventory do
        filter = template_car_inventory.get_filter(j)
        if commitupdate then
          target_car_inventory.set_filter(j, filter)
        end
      end
    end
  end

end


local function copy_trains(template_train, trains_to_update, commitupdate)

  local template_schedule = template_train.schedule

  local trains_updated = {}

  for _, train in ipairs(trains_to_update) do

    if (train.id ~= template_train.id) then

      update_train_schedule(template_schedule, train, commitupdate)

      update_train_filter(template_train, train, commitupdate)

      trains_updated[#trains_updated+1] = train
      
    end
  end

  local train_ids = array_to_string{array=trains_updated, fieldname='id'}

  if commitupdate then
    game.player.print('[COMMIT mode] Updated ' .. #trains_updated .. 
    ' trains to the scheduling of ' .. template_train.id .. '. {' .. train_ids .. '}')
  else
    game.player.print('[LIST mode] There are ' .. #trains_updated .. 
    ' trains can be updated to the scheduling of ' .. template_train.id .. '. {' .. train_ids .. '}')
  end
end

-- update the trains starts with same station list to 
-- the same scheduling as the template train
local function update_trains(template_train_id, station_list, commitupdate)

  local template_train = get_train_by_id(template_train_id)

  if (template_train == nil) then
    game.player.print('Can NOT find the template train with id of ' .. template_train_id)
    debug_log('update_trains', 'Can NOT find the template train with id of ' .. template_train_id)
  else

    game.player.print('Found the template train with id of ' .. template_train.id)
    debug_log('update_trains', 'The template train to use is: (' .. trains_to_string({template_train}) .. ')')
    
    local trains_to_update = get_train_by_stations(station_list)

    debug_log('update_trains', 'Trains to be updated: ' .. trains_to_string(trains_to_update))

    copy_trains(template_train, trains_to_update, commitupdate)

    debug_log('update_trains', 'After updating: ' .. trains_to_string(trains_to_update))
  end


end

local function inspect_trains(station_list)

  local trains_to_inspect = get_train_by_stations(station_list)

  debug_log('inspect_trains', 'Inspecting: ' .. trains_to_string(trains_to_inspect))

end

update_trains(410, {'n-iore-supply-8', 'n-ismelter-8'}, false)

-- inspect_trains({'n-iore-supply-8', 'n-ismelter-8'})