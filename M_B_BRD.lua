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

 --no need to do a replace_textually
function EEex_HookBardThieving()
   local actorID = EEex_GetActorIDSelected()
   local class = EEex_GetActorClass(actorID)
   if class == 5 then
		return 4 -- I'm totally a thief
	else
		return class
	end
end