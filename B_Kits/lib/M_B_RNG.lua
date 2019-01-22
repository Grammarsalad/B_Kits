EEex_AddResetListener(function()
    Infinity_DoFile("M_B_RNG")
end)

--------------------------------------------------
--                  Ranger                     --
--------------------------------------------------
outerConfig = 0

function EEex_ActionbarListener(config)
	outerConfig = config
        local actorID = EEex_GetActorIDSelected()
    if
       config == 11
    then
        EEex_SetActionbarButton(0x4, EEex_ACTIONBAR_TYPE.FIND_TRAPS)
    elseif
        EEex_GetActorClass(actorID) == 12
        and config == 11
    then
        EEex_SetActionbarButton(0x0, EEex_ACTIONBAR_TYPE.THIEVING)
    end
end
EEex_AddActionbarListener(EEex_ActionbarListener)