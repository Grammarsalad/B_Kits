
EEex_AddResetListener(function()
    Infinity_DoFile("M_BDebug")
end)

function getActionbarButton(buttonIndex)
    if buttonIndex < 0 or buttonIndex > 11 then
        error("buttonIndex out of bounds", 2)
    end
    local ecx = rdword(rdword(0x93FDBC) + 0xD14)
    local actionbarAddress = rdword(rdword(ecx + rbyte(ecx + 0x3DA0, 0) * 4 + 0x3DA4) + 0x204) + 0x2654
    return rdword(actionbarAddress + 0x1440 + buttonIndex * 0x4)
end

function B3ActionbarDebug(config)
    Infinity_DisplayString(" ")
    Infinity_DisplayString("DEBUG: [Engine] Actionbar Config => "..config)
    for i = 0, 11, 1 do
        Infinity_DisplayString("DEBUG: [Engine] Actionbar Button["..i.."] => "..getActionbarButton(i))
    end
end
addActionbarListener(B3ActionbarDebug)