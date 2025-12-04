-------------------------------------------------------------
-- Gas Station Blips Loader
-------------------------------------------------------------

CreateThread(function()

    -- Wait for config + other scripts to load
    Wait(500)

    if not Config.EnableGasStationBlips then
        print("[GAS BLIPS] Disabled by config.")
        return
    end

    -- Load JSON file
    local raw = LoadResourceFile(GetCurrentResourceName(), "gasstations.json")
    if not raw then
        print("[GAS BLIPS] ERROR: Could not load gasstations.json")
        return
    end

    local stations = json.decode(raw)
    if not stations then
        print("[GAS BLIPS] ERROR: JSON parse failed!")
        return
    end

    print("[GAS BLIPS] Creating blips for " .. tostring(#stations) .. " gas stations...")

    -- Loop through stations
    for _, station in ipairs(stations) do
        if station.coords then
            local x = station.coords.x
            local y = station.coords.y
            local z = station.coords.z

            local blip = AddBlipForCoord(x, y, z)
            SetBlipSprite(blip, Config.GasBlipSprite)
            SetBlipDisplay(blip, 4)
            SetBlipScale(blip, Config.GasBlipScale)
            SetBlipColour(blip, Config.GasBlipColor)
            SetBlipAsShortRange(blip, true)

            BeginTextCommandSetBlipName("STRING")
            AddTextComponentString("Gas Station")
            EndTextCommandSetBlipName(blip)
        end
    end

end)
