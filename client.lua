---------------------------------------------------------
-- FIVEM JUST GAS FUELING SYSTEM
-- Version 1.0 // 12/01/25
-- Published by: GttiqwT
-- Made mostly using chatgpt
-- Very configurable, adds gas HUD, jerry can refilling, blips etc!
---------------------------------------------------------

local vehicleFuel = {}
local gasStations = nil
local isRefueling = false
local currentVeh = nil
local hasFuelCan = false

-------------------------------------------------------------
-- Load Gas Station JSON
-------------------------------------------------------------
CreateThread(function()
    local raw = LoadResourceFile(GetCurrentResourceName(), "gasstations.json")
    if raw then
        gasStations = json.decode(raw)
        if gasStations then
            print("[FUEL] Loaded " .. tostring(#gasStations) .. " gas stations.")
        else
            print("[FUEL] ERROR: gasstations.json could not be parsed!")
            gasStations = {}
        end
    else
        print("[FUEL] ERROR: Could not load gasstations.json")
        gasStations = {}
    end
end)

---------------------------------------------------------
-- Fuel Helpers (Bound to Vehicle Entity Number)
---------------------------------------------------------
local vehicleFuel = {}

-- Get a unique key for each vehicle
local function getVehicleKey(veh)
    if not DoesEntityExist(veh) then return nil end
    return tostring(NetworkGetNetworkIdFromEntity(veh))
end

-- Get fuel for a vehicle
local function getFuel(veh)
    local key = getVehicleKey(veh)
    if not key then return 0 end
    if not vehicleFuel[key] then
        vehicleFuel[key] = math.random(40, 100) -- initial fuel if not set
    end
    return vehicleFuel[key]
end

-- Set fuel for a vehicle
local function setFuel(veh, lvl)
    local key = getVehicleKey(veh)
    if not key then return end
    vehicleFuel[key] = math.max(0, math.min(100, lvl))
end


---------------------------------------------------------
-- DrawS 3D Text for gas stations
---------------------------------------------------------
local function DrawText3D(x, y, z, text)
    SetTextScale(0.35, 0.35)
    SetTextFont(4)
    SetTextProportional(1)
    SetTextColour(255, 255, 255, 215)
    SetTextCentre(true)
    SetTextEntry("STRING")
    AddTextComponentString(text)
    SetDrawOrigin(x, y, z, 0)
    DrawText(0.0, 0.0)
    ClearDrawOrigin()
end

---------------------------------------------------------
-- Fuel Drain Loop
---------------------------------------------------------
CreateThread(function()
    while true do
        Wait(1000)
        local ped = PlayerPedId()
        local veh = GetVehiclePedIsIn(ped, false)

        if veh ~= 0 and GetPedInVehicleSeat(veh, -1) == ped then
            local fuel = getFuel(veh)
            local engineOn = GetIsVehicleEngineRunning(veh)
            local speed = GetEntitySpeed(veh) -- meters per second

            -- Only drain fuel if engine is running
            if engineOn then
                local drain = speed/2 * Config.FuelDrainRate + 0.01
                setFuel(veh, fuel - drain)

                -- Stop engine if fuel hits 0
                if fuel <= 0 then
                    SetVehicleEngineOn(veh, false, true, true)
                end
            end
            -- If engine is off, do not drain fuel (vehicle can coast)
        end
    end
end)


---------------------------------------------------------
-- Fuel HUD Loop with Border
---------------------------------------------------------
CreateThread(function()
    while true do
        Wait(0)
        local ped = PlayerPedId()
        local veh = GetVehiclePedIsIn(ped, false)
        if veh ~= 0 and GetPedInVehicleSeat(veh, -1) == ped then
            local fuel = getFuel(veh)

            local x = Config.HUD.X
            local y = Config.HUD.Y
            local w = Config.HUD.Width
            local h = Config.HUD.Height
            local borderSize = 0.002  -- thickness of the border

            -- Draw border
			DrawRect(x + w/2, y, w + borderSize*2, h + borderSize*2, 
				Config.HUD.BorderColor.R, Config.HUD.BorderColor.G, Config.HUD.BorderColor.B, Config.HUD.BorderColor.A)

			-- Draw background
			DrawRect(x + w/2, y, w, h, 
				Config.HUD.BackgroundColor.R, Config.HUD.BackgroundColor.G, Config.HUD.BackgroundColor.B, Config.HUD.BackgroundColor.A)

			-- Draw fuel fill
			DrawRect(x + (fuel/100)*w/2, y, (fuel/100)*w, h, 
				Config.HUD.FuelColor.R, Config.HUD.FuelColor.G, Config.HUD.FuelColor.B, Config.HUD.FuelColor.A)


            -- Fuel percentage text
            SetTextFont(4)
            SetTextScale(0.35, 0.35)
            SetTextColour(255, 255, 255, 255)
            SetTextCentre(true)
            SetTextEntry("STRING")
            AddTextComponentString(string.format("Fuel: %.0f%%", fuel))
            DrawText(x + w/2, y - 0.012)
        end
    end
end)

---------------------------------------------------------
-- Fuel Can Spawning + Pickup
---------------------------------------------------------
local canModel = `prop_jerrycan_01a`
local spawnedCans = {}

if Config.EnableFuelCans then
    -- Spawn all cans at stations
    CreateThread(function()
        RequestModel(canModel)
        while not HasModelLoaded(canModel) do Wait(10) end

        if gasStations then
            for _, station in ipairs(gasStations) do
                if station.hasFuelCan then
                    local obj = CreateObject(canModel, station.coords.x, station.coords.y, station.coords.z - 1.0, true, true, true)
                    PlaceObjectOnGroundProperly(obj)
                    spawnedCans[#spawnedCans + 1] = obj
                end
            end
        end
    end)

    -- Pickup thread
    CreateThread(function()
        while true do
            Wait(0)
            local ped = PlayerPedId()
            local px, py, pz = table.unpack(GetEntityCoords(ped))

            for i = #spawnedCans, 1, -1 do
                local obj = spawnedCans[i]
                if DoesEntityExist(obj) then
                    local ox, oy, oz = table.unpack(GetEntityCoords(obj))
                    local dist = #(vector3(px, py, pz) - vector3(ox, oy, oz))

                    if dist < 1.5 then
                        DrawText3D(ox, oy, oz + 0.3, "~g~Press E to pick up Fuel Can")
                        -- Pickup key (E)
                        if IsControlJustPressed(0, 38) then
                            -- Give the player a jerry can in weapon wheel
                            GiveWeaponToPed(ped, `WEAPON_PETROLCAN`, 4500, false, true)
                            DeleteObject(obj)
                            table.remove(spawnedCans, i)
                            print("[FUEL] Jerry Can added to weapon wheel!")
                        end
                    end
                else
                    table.remove(spawnedCans, i)
                end
            end
        end
    end)
end


---------------------------------------------------------
-- Refueling logic
---------------------------------------------------------
CreateThread(function()
    while true do
        Wait(0)
        local ped = PlayerPedId()
        local veh = GetVehiclePedIsIn(ped, false)
        if veh == 0 or not gasStations then goto continue end

        local px, py, pz = table.unpack(GetEntityCoords(ped))
        local nearStation = nil

        -- Check nearest gas station with station.radius override
        for _, station in ipairs(gasStations) do
            local radius = station.radius or Config.StationRange
            local dist = #(vector3(px, py, pz) - vector3(station.coords.x, station.coords.y, station.coords.z))

            if dist < radius then
                nearStation = station
                DrawText3D(
                    station.coords.x,
                    station.coords.y,
                    station.coords.z + 0.3,
                    "~g~Press Horn then hold Spacebar to refuel"
                )
                break
            end
        end

        -- Start refueling using the nearest station
        if nearStation and not isRefueling then
            if IsControlJustPressed(0, Config.RefuelStartKeys.keyboard)
            or IsControlJustPressed(0, Config.RefuelStartKeys.controller) then

                currentVeh = veh
                isRefueling = true
                SetVehicleEngineOn(currentVeh, false, true, true)

                CreateThread(function()
                    while isRefueling do
                        Wait(1000)

                        if not DoesEntityExist(currentVeh) then
                            isRefueling = false
                            break
                        end

                        local fuel = getFuel(currentVeh)
                        if fuel >= 100 then
                            isRefueling = false
                            break
                        end

                        -- Stop if engine turns on mid-refuel
                        if GetIsVehicleEngineRunning(currentVeh) then
                            isRefueling = false
                            break
                        end

                        -- Hold key requirement
                        local holdingKeys =
                            IsControlPressed(0, Config.RefuelHoldKeys.keyboard) or
                            IsControlPressed(0, Config.RefuelHoldKeys.controller)

                        if holdingKeys then
                            setFuel(currentVeh, math.min(fuel + Config.RefuelRate, 100))
                        else
                            isRefueling = false
                        end
                    end
                end)
            end
        end

        ::continue::
    end
end)

---------------------------------------------------------
-- Fuel Can Refuel With Animation + Progress Bar
---------------------------------------------------------
local isCanRefueling = false
local canRefuelProgress = 0
local refuelDuration = 5000 -- 5 seconds in ms
local vehicleRefuelAmount = 50 -- amount of fuel to give per can use

CreateThread(function()
    while true do
        Wait(0)
        local ped = PlayerPedId()
        local pos = GetEntityCoords(ped)

        -- Check if player has jerry can equipped
        local currentWeapon = GetSelectedPedWeapon(ped)
        local hasCanEquipped = currentWeapon == `WEAPON_PETROLCAN`
        if not hasCanEquipped then
            isCanRefueling = false
            canRefuelProgress = 0
        end

        -- Detect nearby vehicle to refuel
        local targetVeh = nil
        local vehicles = GetGamePool('CVehicle')
        for _, v in ipairs(vehicles) do
            local dist = #(pos - GetEntityCoords(v))
            if dist < 3.0 then
                targetVeh = v
                break
            end
        end

		-- Only show text and allow refueling if jerry can is equipped
        if targetVeh and hasCanEquipped and not isCanRefueling then
            local fuel = getFuel(targetVeh)
            if fuel >= 100 then
                DrawText3D(pos.x, pos.y, pos.z + 0.5, "~r~Vehicle is full of gas")
            else
                DrawText3D(pos.x, pos.y, pos.z + 0.5, "~g~Hold E to fuel vehicle")

                local holdingKey = IsControlPressed(0, Config.RefuelStartKeys.keyboard) or
                                   IsControlPressed(0, Config.RefuelStartKeys.controller)

            if holdingKey then
                isCanRefueling = true
                canRefuelProgress = 0

                -- Start animation
                RequestAnimDict("anim@amb@clubhouse@tutorial@bkr_tut_ig3@")
                while not HasAnimDictLoaded("anim@amb@clubhouse@tutorial@bkr_tut_ig3@") do Wait(0) end
                TaskPlayAnim(ped, "anim@amb@clubhouse@tutorial@bkr_tut_ig3@", "machinic_loop_mechandplayer", 8.0, -8.0, -1, 49, 0, false, false, false)

                local startTime = GetGameTimer()

                -- Refuel loop
                CreateThread(function()
                    while isCanRefueling do
                        Wait(0)
                        local currentTime = GetGameTimer()
                        canRefuelProgress = math.min((currentTime - startTime) / refuelDuration * 100, 100)

                        -- HUD config (I did this myself cause gpt was being dumb LOL)
                        local x = Config.HUD.X
                        local y = Config.HUD.Y
                        local w = Config.HUD.Width
                        local h = Config.HUD.Height
                        local fuelColor = Config.HUD.FuelColor
						local borderColor = Config.HUD.BorderColor
						local bgColor = Config.HUD.BackgroundColor
						local borderSize = 0.002
						
						--Draw them I did this myself cause gpt was being dumb LOL)
                        DrawRect(x + w/2, y, w + borderSize*2, h + borderSize*2, borderColor.R, borderColor.G, borderColor.B, borderColor.A)
                        DrawRect(x + w/2, y, w, h, bgColor.R, bgColor.G, bgColor.B, bgColor.A)
                        DrawRect(x + (canRefuelProgress/100)*w/2, y, (canRefuelProgress/100)*w, h, fuelColor.R, fuelColor.G, fuelColor.B, fuelColor.A)
						
                        -- Draw percentage text
                        SetTextFont(4)
                        SetTextScale(0.35, 0.35)
                        SetTextColour(255,255,255,255)
                        SetTextCentre(true)
                        SetTextEntry("STRING")
                        AddTextComponentString(string.format("Refueling: %.0f%%", canRefuelProgress))
                        DrawText(x + w/2, y - 0.012)

                        -- Cancel if player moves
                        local newPos = GetEntityCoords(ped)
                        if #(newPos - pos) > 0.5 then
                            isCanRefueling = false
                            ClearPedTasks(ped)
                            canRefuelProgress = 0
                            break
                        end

                        -- Stop if player releases the refuel key
                        local stillHolding = IsControlPressed(0, Config.RefuelStartKeys.keyboard) or
                                             IsControlPressed(0, Config.RefuelStartKeys.controller)
                        if not stillHolding then
                            isCanRefueling = false
                            ClearPedTasks(ped)
                            canRefuelProgress = 0
                            break
                        end

							-- Complete refuel
							if canRefuelProgress >= 100 then
								local fuel = getFuel(targetVeh)
								setFuel(targetVeh, math.min(fuel + vehicleRefuelAmount, 100))
								isCanRefueling = false
								ClearPedTasks(ped)
								canRefuelProgress = 0
								break
							end
						end
					end)
				end
			end
		end
	end
end)
---------------------------------------------------------
--THIS IS A FREE SCRIPT. DO NOT REDISTRIBUTE OR SELL THIS.
--YOU MAY MODIFY THIS SCRIPT BUT PLEASE CREDIT ME, THANKS: GTTIQWT
---------------------------------------------------------
