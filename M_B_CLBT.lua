
EEex_AddResetListener(function()
    Infinity_DoFile("M_B_CLBT")
end)

--------------------------------------------------
--               inquisitor                     --
--------------------------------------------------
--detect traps instead of turn undead
function B3ActionbarListener(config)
	local actorID = getActorIDSelected()
    if 
       config == 0x5
       and getActorClass(actorID) == 0x6
       and getActorKit(actorID) == 0x4005
    then
        setActionbarButton(0x5, ACTIONBAR_TYPE.FIND_TRAPS)
    end
end
addActionbarListener(B3ActionbarListener)

--------------------------------------------------
--               blackguard                     --
--------------------------------------------------
--add stealth in place of defend
function B3ActionbarListener(config)
	local actorID = getActorIDSelected()
    if 
       config == 0x5
       and getActorClass(actorID) == 0x6
       and getActorKit(actorID) == 0x4020
    then
        setActionbarButton(0x4, ACTIONBAR_TYPE.STEALTH)
    end
end
addActionbarListener(B3ActionbarListener)

--------------------------------------------------
--                   monk                       --
--------------------------------------------------
--add thieving in place of defend
function B3ActionbarListener(config)
	local actorID = getActorIDSelected()
    if 
       config == 18
       and getActorClass(actorID) == 20
    then
        setActionbarButton(0x4, ACTIONBAR_TYPE.THIEVING)
    end
end
addActionbarListener(B3ActionbarListener)

--------------------------------------------------
--               beast master                   --
--------------------------------------------------
--add detect trap/illusion in place of defend
function B3ActionbarListener(config)
	local actorID = getActorIDSelected()
    if 
       config == 11
       and getActorClass(actorID) == 12
       and getActorKit(actorID) == 0x4009
    then
        setActionbarButton(0x4, ACTIONBAR_TYPE.FIND_TRAPS)
    end
end
addActionbarListener(B3ActionbarListener)

--------------------------------------------------
--                  stalker                     --
--------------------------------------------------
--add detect trap/illusion in place of defend
function B3ActionbarListener(config)
	local actorID = getActorIDSelected()
    if 
       config == 11
       and getActorClass(actorID) == 12
       and getActorKit(actorID) == 0x4008
    then
        setActionbarButton(0x4, ACTIONBAR_TYPE.THIEVING)    --thieving instead of defend
    end
end
addActionbarListener(B3ActionbarListener)

--------------------------------------------------
--                 Barbarian                    --
--------------------------------------------------
--add detect trap/illusion in place of defend
function B3ActionbarListener(config)
	local actorID = getActorIDSelected()
    if 
       config == 1
       and getActorClass(actorID) == 2
       and getActorKit(actorID) == 0x40000000
    then
        setActionbarButton(0x4, ACTIONBAR_TYPE.FIND_TRAPS)
    end
end
addActionbarListener(B3ActionbarListener)


--------------------------------------------------
--               cleric/thief                   --
--------------------------------------------------
--[[ No good solution right now
--Eliminates thievery in special abilities--
function B3ActionbarListener(config)
	local actorID = getActorIDSelected()
    if
       config == 23
       and getActorClass(actorID) == 15
    then
        setActionbarButton(0x0, ACTIONBAR_TYPE.NONE)
    end
end
addActionbarListener(B3ActionbarListener)

--adds thieving in place of 2nd weapon
function B3ActionbarListener(config)
	local actorID = getActorIDSelected()
    if
       config == 14
       and getActorClass(actorID) == 15
    then
        setActionbarButton(0x4, ACTIONBAR_TYPE.THIEVING)
    end
end
addActionbarListener(B3ActionbarListener)

--]]


--
--[[
--bard
function B3ActionbarListener(config)
	local actorID = getActorIDSelected()
    if
       config == 0x4
       and getActorClass(actorID) == 5
    then
        setActionbarButton(0x3, ACTIONBAR_TYPE.THIEVING)
        setActionbarButton(0x4, ACTIONBAR_TYPE.THIEVING)
        setActionbarButton(0x5, ACTIONBAR_TYPE.THIEVING)
    end
end
addActionbarListener(B3ActionbarListener)

function B3ActionbarListener(config)
	local actorID = getActorIDSelected()
    if
       getActorClass(actorID) == 15
    then
        setActionbarButton(0x4, ACTIONBAR_TYPE.THIEVING)
    end
end
addActionbarListener(B3ActionbarListener)

--]]