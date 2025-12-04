Config = {}

Config.EnableGasStationBlips = true     -- Turn all gas station map blips on/off. true by default
Config.GasBlipSprite = 361              -- default: 361
Config.GasBlipColor = 0                 -- default: 0
Config.GasBlipScale = 1.0               -- default: 1.0
Config.StationRange = 6.0				-- If a value is not set, it will use this instead. default: 6.0


-- Fuel drain per second (speed/2 * rate + 0.01) default: 0.005 (lower lasts longer)
Config.FuelDrainRate = 0.005

-- Refuel rate at gas stations (percent per second) default: 4.0
Config.RefuelRate = 4.0

-- DO NOT CHANGE --
Config.CanRefuelRate = 1.0

-- Distance to trigger gas station interaction default is: 8
Config.StationRange = 8.0

-- Buttons to start refueling (keyboard + controller)
Config.RefuelStartKeys = {
    keyboard = 38,   -- E (HORN) default: 38
    controller = 86  -- left bumper default: 86
}

-- Buttons to hold while refueling (keyboard + controller)
Config.RefuelHoldKeys = {
    keyboard = 22,  -- SPACEBAR (or Xbox X) default: 22
    controller = 18 -- INPUT_A (Xbox A) default: 18
}

-- Allow fuel cans
Config.EnableFuelCans = true

-- Fuel HUD settings
Config.HUD = {
    X = 0.015,   -- X screen coordinate (0.0 left, 1.0 right) default: 0.015
    Y = 0.79,    -- Y screen coordinate (0.0 top, 1.0 bottom) default: 0.79
    Width = 0.14, -- default: 0.14
    Height = 0.02, -- default: 0.02
	FuelColor = {R = 90, G = 100, B = 255, A = 200}, -- both the gas and refueling are synced and use the same values! vvv
    BorderColor = {R = 0, G = 0, B = 0, A = 150},
    BackgroundColor = {R = 0, G = 0, B = 0, A = 150}
}
