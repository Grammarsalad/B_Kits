EEex_AddResetListener(function()
    Infinity_DoFile("M_B_BRD")
end)

--------------------------------------------------
--                  bard                        --
--------------------------------------------------
outerConfig = 0

function EEex_ActionbarListener(config)
	outerConfig = config
        local actorID = EEex_GetActorIDSelected()
    if
       config == 4
    then
        EEex_SetActionbarButton(0x5, EEex_ACTIONBAR_TYPE.FIND_TRAPS)
    end
end
EEex_AddActionbarListener(EEex_ActionbarListener)