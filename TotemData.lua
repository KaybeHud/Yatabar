-- if select(2, UnitClass('player')) ~= "SHAMAN" then
-- 	return
-- end
YatabarConfig = {}


YatabarConfig.totems = {
        ["EARTH"] = {
            { id = 8071, duration = 120 }, -- Earth skin
            { id = 2484, duration = 45 }, -- Earth bind
            { id = 5730, duration = 15 }, -- Stoneclaw
            { id = 8075, duration = 120 }, -- Strenght of Earth
            { id = 8143, duration = 120 }, -- Tremor
        },
        ["FIRE"] = {
            { id = 3599, duration = 30 }, -- Searing
            { id = 1535, duration = 5 }, -- nova
            { id = 8181, duration = 120 }, -- frost resistance
            { id = 8190, duration = 20 }, -- magma
            { id = 8227, duration = 120 }, -- flametongue
            { id = 30706, duration = 120}, --Totem of Wrath
        },
        ["WATER"] = {
            { id = 5394, duration = 60 }, -- healing stream
            { id = 8166, duration = 120 }, -- poison cleansing
            { id = 5675, duration = 60 }, -- manaspring
            { id = 8184, duration = 120 }, -- fire resistance
            { id = 8170, duration = 120 }, -- disease cleansing
            { id = 16190, duration = 12 } -- mana tide
        },
        ["AIR"] = {
            { id = 8177, duration = 45 }, -- grounding
            { id = 10595, duration = 120 }, -- nature resistance
            { id = 8512, duration = 120 }, -- windfury
            { id = 6495, duration = 300 }, -- sentry
            { id = 15107, duration = 120 }, -- windwall
            { id = 8835, duration = 120 }, -- grace of air
            { id = 25908, duration = 120 }, -- tranquil air
            { id = 3738, duration = 120 }, -- Wrath of Air
        }
}
YatabarConfig.spells = {
    TotemicCall = 36936
}
