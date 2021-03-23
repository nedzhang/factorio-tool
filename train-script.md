# To run a script in console

```lua
/c  game.player.print(1234*5678)
```

## List Trains

```lua
/c 

local function log(message)

  local logfile_path = "nz_debug.log"

  game.write_file(logfile_path, message, true)

end

local function get_surface()
  return game.get_surface('nauvis')
end

local function get_train_by_stations(stations)

  local surface = get_surface()
  local trains = surface.get_trains()

  if (stations == nil) then
    return trains
  else 

    local filteredtrainlist = {}

    for trainkey, train in ipairs(trains) 
    do
        --[[game.player.print('Checking train: ' .. trainkey)]]
        --[[
        local motos = train.locomotives['front_movers']
        local traindesc = '{'
        for _, moto in ipairs(motos)
        do
          traindesc = traindesc .. ' ' .. moto.name
        end
        ]]

        local schedule = train.schedule
        
        if (schedule ~= nil) and (#schedule.records > 0) then
          local isamatch = true

          for i, v in ipairs(stations) do
            log('checking for: ' .. v)
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

local function get_train_station_list(train)

  local schedule = train.schedule
  if (schedule ~= nil) then
    --[[local stationlist = ' (' .. #schedule.records .. ')']]
    local stationlist = nil
    for stat, schedulerecord in ipairs(schedule.records)
    do
      if (stationlist == nil) then
        stationlist = schedulerecord.station
      else
        stationlist = stationlist .. ', ' .. schedulerecord.station
      end 
    end

    return stationlist
  else 
    return nil
  end

end

local function print_trains(trains_to_print)

  if (trains_to_print ~= nil) and (#trains_to_print > 0) then

    game.player.print("Printing " .. #trains_to_print .. " train(s)")

    for _, train in ipairs(trains_to_print)
    do
      game.player.print("About to print detail of train #" .. train.id)

      local station_list = get_train_station_list(train)

      game.player.print( 'train id: ' .. train.id .. ' schedule: ' .. station_list)
      
    end
  else 
    game.player.print("trains to print array is nil or empty")
  end

end 

local trains = get_train_by_stations({'n-iore-supply-8', 'n-ismelter-8'})

--[[ number of trains ]]
game.player.print('Number of trains: ' .. #trains)

print_trains(trains)

local template_train = get_train_by_id(381)

--[[game.player.print('We have found the template train with id of ' .. template_train.id)]]

--[[game.player.print('The template train to use is: ')]]

-- [[ can't the print_trains function to print one element train array print_trains({template_train})]]
print_trains({template_train, template_train, template_train})

print_trains(trains)

```