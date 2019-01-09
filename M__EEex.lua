--[[

This is EEex's main file. The vital initialization and hooks are
defined within this file. Please don't edit unless you
ABSOLUTELY know what you are doing... you could very easily cause a game crash in here.

Most new functions that *aren't* hardcoded into the exe are defined in here.
I haven't documented most of them yet, so have a look around.
(But please, again, no touchy!)

--]]

-----------
-- State --
-----------

EEex_ResetListeners = {}

function EEex_AddResetListener(listener)
	table.insert(EEex_ResetListeners, listener)
end

EEex_IgnoreFirstReset = true
function EEex_Reset()
	if not EEex_IgnoreFirstReset then
		local resetListenersCopy = EEex_ResetListeners
		EEex_ResetListeners = {}
		for _, listener in ipairs(resetListenersCopy) do
			listener()
		end
	else
		EEex_IgnoreFirstReset = false
	end
end

---------------------
-- Memory Utililty --
---------------------

function malloc(size)
	return call(0x886FD0, {size}, nil, 0x4)
end

function free(address)
	return call(0x7BF980, {address}, nil, 0x4)
end

function rbyte(address, index)
	return bit32.extract(rdword(address), index * 0x8, 0x8)
end

function rword(address, index)
	return bit32.extract(rdword(address), index * 0x10, 0x10)
end

function wword(address, value)
	for i = 0, 1, 1 do
		B3ex_WriteByte(address + i * 0x2, bit32.extract(value, i * 0x16, 0x8))
	end
end

function wdword(address, value)
	for i = 0, 3, 1 do
		B3ex_WriteByte(address + i, bit32.extract(value, i * 0x8, 0x8))
	end
end

function wstringex(string)
	local stringLength = #string
	local alignedSize = _roundUp(stringLength + 0x1, 0x4)
	local baseAddress = malloc(alignedSize)
	wdword(baseAddress, 0x1)
	wdword(baseAddress + 0x4, stringLength)
	wdword(baseAddress + 0x8, alignedSize)
	local stringAddress = baseAddress + 0xC
	wstring(stringAddress, string)
	return stringAddress
end

function dllcall(dll, proc, args, ecx, pop)
	local procaddress = #dll + 1
	local dlladdress = malloc(procaddress + #proc + 1)
	procaddress = dlladdress + procaddress
	wstring(dlladdress, dll)
	wstring(procaddress, proc)
	local dllhandle = call(rdword(0x8A01D8), {dlladdress}, nil, 0x0)
	local procfunc = call(rdword(0x8A0200), {procaddress, dllhandle}, nil, 0x0)
	local result = call(procfunc, args, ecx, pop)
	free(dlladdress)
	return result
end

--------------------
-- Random Utility --
--------------------

function _roundUp(numToRound, multiple)
	if multiple == 0 then
		return numToRound
	end
	local remainder = numToRound % multiple
	if remainder == 0 then
		return numToRound
	end
	return numToRound + multiple - remainder;
end

----------------------
-- Assembly Writing --
----------------------

function _B3WriteAssembly(address, args)
	local currentWriteAddress = address
	for _, arg in ipairs(args) do
		local argType = type(arg)
		if argType == "string" then
			local processSection = function(section)
				if string.sub(section, 1, 1) == ":" then
					local targetOffset = tonumber(string.sub(section, 2, #section), 16)
					local relativeOffsetNeeded = targetOffset - (currentWriteAddress + 4)
					for i = 0, 3, 1 do
						local byte = bit32.extract(relativeOffsetNeeded, i * 8, 8)
						B3ex_WriteByte(currentWriteAddress, byte)
						currentWriteAddress = currentWriteAddress + 1
					end
				else
					local byte = tonumber(section, 16)
					B3ex_WriteByte(currentWriteAddress, byte)
					currentWriteAddress = currentWriteAddress + 1
				end
			end
			local limit = #arg
			local lastSpace = 0
			for i = 1, limit, 1 do
				local char = string.sub(arg, i, i)
				if char == " " then
					if i - lastSpace > 1 then
						local section = string.sub(arg, lastSpace + 1, i - 1)
						processSection(section)
					end
					lastSpace = i
				end
			end
			if limit - lastSpace > 0 then
				local lastSection = string.sub(arg, lastSpace + 1, limit)
				processSection(lastSection)
			end
		elseif argType == "table" then
			local argSize = #arg
			if argSize == 2 or argSize == 3 then
				local address = arg[1]
				local length = arg[2]
				local relativeFromOffset = arg[3]
				if type(address) == "number" and type(length) == "number" 
					and (not relativeFromOffset or type(relativeFromOffset) == "number")
				then
					if relativeFromOffset then address = address - currentWriteAddress - relativeFromOffset end
					local limit = length - 1
					for i = 0, limit, 1 do
						local byte = bit32.extract(address, i * 8, 8)
						B3ex_WriteByte(currentWriteAddress, byte)
						currentWriteAddress = currentWriteAddress + 1
					end
				else
					error("Variable write argument included invalid data-type!", 2)
				end
			else
				error("Variable write argument did not have at least 2 args!", 2)
			end
		else
			error("Illegal data-type in assembly declaration!", 2)
		end
	end
end

function _B3CalcWriteLength(args)
	local toReturn = 0
	for _, arg in ipairs(args) do
		local argType = type(arg)
		if argType == "string" then
			local processSection = function(section)
				if string.sub(section, 1, 1) == ":" then
					toReturn = toReturn + 4
				else
					toReturn = toReturn + 1
				end
			end
			local limit = #arg
			local lastSpace = 0
			for i = 1, limit, 1 do
				local char = string.sub(arg, i, i)
				if char == " " then
					if i - lastSpace > 1 then
						local section = string.sub(arg, lastSpace + 1, i - 1)
						processSection(section)
					end
					lastSpace = i;
				end
			end
			if limit - lastSpace > 0 then
				local lastSection = string.sub(arg, lastSpace + 1, limit)
				processSection(lastSection)
			end
		elseif argType == "table" then
			local argSize = #arg
			if argSize == 2 or argSize == 3 then
				local address = arg[1]
				local length = arg[2]
				local relativeFromOffset = arg[3]
				if type(address) == "number" and type(length) == "number" 
					and (not relativeFromOffset or type(relativeFromOffset) == "number")
				then
					toReturn = toReturn + length;
				else
					error("Variable write argument included invalid data-type!", 2)
				end
			else
				error("Variable write argument did not have at least 2 args!", 2)
			end
		else
			error("Illegal data-type in assembly declaration!", 2)
		end
	end
	return toReturn;
end

-- NOTE: Same as _B3WriteAssembly(), but writes to a dynamically
-- allocated memory space instead of a provided address.
-- Very useful for writing new executable code into memory.
function _B3WriteAssemblyAuto(assembly)
	local reservedAddress = _B3ReserveCodeMemory(_B3CalcWriteLength(assembly))
	_B3WriteAssembly(reservedAddress, assembly)
	return reservedAddress
end

function _B3WriteAssemblyFunction(functionName, assembly)
	local functionAddress = _B3WriteAssemblyAuto(assembly)
	B3ex_ExposeToLua(functionAddress, functionName)
end

----------------------
--  Bits Utilility  -- 
----------------------

function B3Flags(flags)
	local result = 0x0
	for _, flag in ipairs(flags) do
		result = bit32.bor(result, flag)
	end
	return result
end

function isBitSet(original, isSetIndex)
	local mask = bit32.lshift(0x1, isSetIndex)
	return bit32.band(original, mask) == mask
end

function isMaskSet(original, isSetMask)
	return bit32.band(original, tonumber(toSetMask, 2)) == isSetMask
end

function isBitUnset(original, isSetIndex)
	return bit32.band(original, bit32.lshift(0x1, isSetIndex)) == 0x0
end

function isMaskUnset(original, isUnsetMask)
	return bit32.band(original, tonumber(toSetMask, 2)) == 0x0
end

function setBit(original, toSetIndex)
	return bit32.bor(original, bit32.lshift(0x1, toSetIndex))
end

function setMask(original, toSetMask)
	return bit32.bor(original, tonumber(toSetMask, 2))
end

function unsetBit(original, toUnsetIndex)
	return bit32.band(original, bit32.bnot(bit32.lshift(0x1, toUnsetIndex)))
end

function unsetMask(original, toUnsetmask)
	return bit32.band(original, bit32.bnot(tonumber(toUnsetmask, 2)))
end

function toBits(num, bits)
    bits = bits or math.max(1, select(2, math.frexp(num)))
    local t = {}       
    for b = bits, 1, -1 do
        t[b] = math.fmod(num, 2)
        num = math.floor((num - t[b]) / 2)
    end
    local result = ""
    for i = 1, #t, 1 do
    	result = result..t[i]
    end
    return result
end

function toHex(number, minLength)
	local hexString = string.format("%x", number)
	local wantedLength = (minLength or 0) - #hexString
	for i = 1, wantedLength, 1 do
		hexString = "0"..hexString
	end
	hexString = hexString:upper()
	return "0x"..hexString
end

-------------------------------
-- Dynamic Memory Allocation --
-------------------------------

function _B3GetAllocGran()
	local systemInfo = malloc(0x24)
	dllcall("Kernel32", "GetSystemInfo", {systemInfo}, nil, 0x0)
	local allocGran = rdword(systemInfo + 0x1C)
	free(systemInfo)
	return allocGran
end

function _B3VirtualAlloc(dwSize, flProtect)
	-- 0x1000 = MEM_COMMIT
	-- 0x2000 = MEM_RESERVE
	return dllcall("Kernel32", "VirtualAlloc", {flProtect, B3Flags({0x1000, 0x2000}), dwSize, 0x0}, nil, 0x0)
end

_B3CodePageAllocations = {}
-- NOTE: Please don't call this directly. This is used internally
-- by _B3ReserveCodeMemory() to allocate additional code pages
-- when needed. If you ignore this message, god help you.
function _B3AllocCodePage(size)
	local allocGran = _B3GetAllocGran()
	size = _roundUp(size, allocGran)
	local address = _B3VirtualAlloc(size, 0x40)
	local initialEntry = {}
	initialEntry.address = address
	initialEntry.size = size
	initialEntry.reserved = false
	local codePageEntry = {initialEntry}
	table.insert(_B3CodePageAllocations, codePageEntry)
	return codePageEntry
end

-- NOTE: Dynamically allocates and reserves executable memory for
-- new code. No reason to use instead of _B3WriteAssemblyAuto,
-- unless you want to reserve memory for later use. 
-- Supports filling holes caused by freeing code reservations,
-- (if you would ever want to do that?...), though freeing is not
-- currently implemented.
function _B3ReserveCodeMemory(size)
	local reservedAddress = -1
	local processCodePageEntry = function(codePage)
		for i, allocEntry in ipairs(codePage) do
			if not allocEntry.reserved and allocEntry.size >= size then
				local memLeftOver = allocEntry.size - size
				if memLeftOver > 0 then
					local newAddress = allocEntry.address + size
					local nextEntry = _B3CodePageAllocations[i + 1]
					if nextEntry then
						if not nextEntry.reserved then
							local addressDifference = nextEntry.address - newAddress
							nextEntry.address = newAddress
							nextEntry.size = allocEntry.size + addressDifference
						else
							local newEntry = {}
							newEntry.address = newAddress
							newEntry.size = memLeftOver
							newEntry.reserved = false
							table.insert(codePage, newEntry, i + 1)
						end
					else
						local newEntry = {}
						newEntry.address = newAddress
						newEntry.size = memLeftOver
						newEntry.reserved = false
						table.insert(codePage, newEntry)
					end
				end
				allocEntry.size = size
				allocEntry.reserved = true
				reservedAddress = allocEntry.address
				return true
			end
		end
		return false
	end
	for _, codePage in ipairs(_B3CodePageAllocations) do
		if processCodePageEntry(codePage) then
			break
		end
	end
	if reservedAddress == -1 then
		local newCodePage = _B3AllocCodePage(size)
		processCodePageEntry(newCodePage)
	end
	return reservedAddress
end

------------
-- !MAIN! --
------------

function B3ex_Main()

	-- !!!----------------------------------------------------------------!!!
	--  | B3ex_Init() is the only new function that is exposed by default. |
	--  | It does several things:                                          |
    --  |                                                                  |
	--  |   1. Exposes the hardcoded function B3ex_WriteByte()             |
    --  |                                                                  |
	--  |   2. Exposes the hardcoded function B3ex_ExposeToLua()           |
    --  |                                                                  |
	--  |   3. Calls VirtualAlloc() with the following params =>           |
	--  |        lpAddress = 0                                             |
    --  |        dwSize = 0x1000                                           |
    --  |        flAllocationType = MEM_COMMIT | MEM_RESERVE               |
    --  |        flProtect = PAGE_EXECUTE_READWRITE                        |
    --  |                                                                  |
    --  |   4. Passes along the VirtualAlloc()'s return value              |
    -- !!! ---------------------------------------------------------------!!!
	local initialMemory = B3ex_Init()

	-- Inform the dynamic memory system of the hardcoded starting memory.
	-- (Had to hardcode initial memory because I couldn't include a VirtualAlloc wrapper
	-- without using more than the 340 alignment bytes available.)
	table.insert(_B3CodePageAllocations, {
		{["address"] = initialMemory, ["size"] = 0x1000, ["reserved"] = false}
	})

	_B3WriteAssemblyFunction("rdword", {
		"55 8B EC 53 51 52 56 57 6A 00 6A 01 FF 75 08 "..
		"E8 :4B54D0 "..
		"83 C4 0C "..
		"E8 :85C3C0 "..
		"FF 30 DB 04 24 83 EC 04 DD 1C 24 FF 75 08 "..
		"E8 :4B5960 "..
		"83 C4 0C B8 01 00 00 00 5F 5E 5A 59 5B 5D C3"
	})
	_B3WriteAssemblyFunction("rstring", {
		"55 8B EC 53 51 52 56 57 6A 00 6A 01 FF 75 08 "..
		"E8 :4B54D0 "..
		"83 C4 0C "..
		"E8 :85C3C0 "..
		"50 FF 75 08 "..
		"E8 :4B5A40 "..
		"83 C4 08 B8 01 00 00 00 5F 5E 5A 59 5B 5D C3"
	})
	_B3WriteAssemblyFunction("call", {
		"55 8B EC 53 51 52 56 57 6A 02 FF 75 08 "..
		"E8 :4B57B0 "..
		"83 C4 08 85 C0 74 3C 8B F8 BE 01 00 00 00 56 6A 02 FF 75 08 "..
		"E8 :4B5D40 "..
		"83 C4 0C 6A 00 6A FF FF 75 08 "..
		"E8 :4B54D0 "..
		"83 C4 0C "..
		"E8 :85C3C0 "..
		"50 6A FE FF 75 08 "..
		"E8 :4B50C0 "..
		"83 C4 08 46 3B F7 7E CB 6A 00 6A 03 FF 75 08 "..
		"E8 :4B54D0 "..
		"83 C4 0C "..
		"E8 :85C3C0 "..
		"50 6A 00 6A 01 FF 75 08 "..
		"E8 :4B54D0 "..
		"83 C4 0C "..
		"E8 :85C3C0 "..
		"59 FF D0 50 DB 04 24 83 EC 04 DD 1C 24 FF 75 08 "..
		"E8 :4B5960 "..
		"83 C4 0C 6A 00 6A 04 FF 75 08 "..
		"E8 :4B54D0 "..
		"83 C4 0C "..
		"E8 :85C3C0 "..
		"03 E0 B8 01 00 00 00 5F 5E 5A 59 5B 5D C3"
	})
	_B3WriteAssemblyFunction("wstring", {
		"55 8B EC 53 51 52 56 57 6A 00 6A 01 FF 75 08 "..
		"E8 :4B54D0 "..
		"83 C4 0C "..
		"E8 :85C3C0 "..
		"8B F8 6A 00 6A 02 FF 75 08 "..
		"E8 :4B5710 "..
		"83 C4 0C 8B F0 8A 06 88 07 46 47 80 3E 00 75 F5 C6 07 00 B8 00 00 00 00 5F 5E 5A 59 5B 5D C3"
	})
	_B3WriteAssemblyFunction("ruserdata", {
		"55 8B EC 53 51 52 56 57 6A 01 FF 75 08 "..
		"E8 :4B5840 "..
		"83 C4 08 50 DB 04 24 83 EC 04 DD 1C 24 FF 75 08 "..
		"E8 :4B5960 "..
		"83 C4 0C B8 01 00 00 00 5F 5E 5A 59 5B 5D C3"
	})
	_B3WriteAssemblyFunction("tolightuserdata", {
		"55 8B EC 53 51 52 56 57 6A 00 6A 01 FF 75 08 "..
		"E8 :4B54D0 "..
		"83 C4 0C "..
		"E8 :85C3C0 "..
		"50 FF 75 08 "..
		"E8 :4B5BF0 "..
		"83 C4 08 B8 01 00 00 00 5F 5E 5A 59 5B 5D C3"
	})
end
B3ex_Main()

-------------------------
-- !CODE MANIPULATION! --
-------------------------

-- Don't use this unless
-- you REALLY know what you are doing.
-- Enables writing to the .text section of the
-- exe (code).
function _B3DisableCodeProtection()
	local temp = malloc(0x4)
	-- 0x40 = PAGE_EXECUTE_READWRITE
	-- 0x401000 = Start of .text section in memory.
	-- 0x49F000 = Size of .text section in memory.
	dllcall("Kernel32", "VirtualProtect", {temp, 0x40, 0x49F000, 0x401000}, nil, 0x0)
	free(temp)
end

-- If you were crazy enough to use 
-- _B3DisableCodeProtection(), please
-- use this to reverse your bad decisions.
-- Reverts the .text section protections back
-- to default.
function _B3EnableCodeProtection()
	local temp = malloc(0x4)
	-- 0x20 = PAGE_EXECUTE_READ
	-- 0x401000 = Start of .text section in memory.
	-- 0x49F000 = Size of .text section in memory.
	dllcall("Kernel32", "VirtualProtect", {temp, 0x20, 0x49F000, 0x401000}, nil, 0x0)
	free(temp)
end

--------------------
--  Engine Hooks  --
--------------------

Infinity_DoFile("EEex_Act") -- New Actions (B3Lua)
Infinity_DoFile("EEex_AHo") -- Actions Hook
Infinity_DoFile("EEex_Bar") -- Actionbar Hook
Infinity_DoFile("EEex_Brd") -- Bard Thieving Hook
Infinity_DoFile("EEex_Key") -- keyPressed / keyReleased Hook
Infinity_DoFile("EEex_Tip") -- isTooltipDisabled Hook

---------------------
--  Input Details  --
---------------------

function getTrueMousePos()
	local ecx = rdword(0x93FDB8)
	local mouseX = rdword(ecx + 0xC40)
	local mouseY = rdword(ecx + 0xC44)
	return mouseX, mouseY
end

function isCursorWithin(x, y, width, height)
	local mouseX, mouseY = getTrueMousePos()
	return mouseX >= x and mouseX <= (x + width)
	       and mouseY >= y and mouseY <= (y + height)
end

function isCursorWithinMenu(menuName, menuItemName)
	local offsetX, offsetY = Infinity_GetOffset(menuName)
	local itemX, itemY, itemWidth, itemHeight = Infinity_GetArea(menuItemName)
	return isCursorWithin(offsetX + itemX, offsetY + itemY, itemWidth, itemHeight)
end

function getFPS()
	return rdword(0x938778)
end

function translateViewportXY(mouseGameX, mouseGameY)
	local eax = rdword(0x93FDBC)
	local ecx = rdword(eax + 0xD14)
	eax = rbyte(ecx + 0x3DA0, 0)
	local esi = rdword(ecx + eax * 4 + 0x3DA4)
	esi = esi + 0x484
	local viewportX = rdword(esi + 0x40) - rdword(esi + 0x58)
	local mouseX = mouseGameX - viewportX
	local viewportY = rdword(esi + 0x44) - rdword(esi + 0x5C)
	local mouseY = mouseGameY - viewportY
	local maxViewportX = rdword(esi + 0x60)
	local maxViewportY = rdword(esi + 0x64)
	local screenWidth, screenHeight = Infinity_GetScreenSize()
	local uiMouseX = math.floor(screenWidth * (mouseX / maxViewportX) + 0.5)
	local uiMouseY = math.floor(screenHeight * (mouseY / maxViewportY) + 0.5)
	return uiMouseX, uiMouseY
end

-------------------------
--  Menu Manipulation  --
-------------------------

function getMenuAddressFromItem(menuItemName)
	return rdword(ruserdata(Infinity_FindUIItemByName(menuItemName)) + 0x4)
end

function getMenuItemAddress(menuItemName)
	return ruserdata(Infinity_FindUIItemByName(menuItemName))
end

function getListScroll(listName)
	local menuData = Infinity_FindUIItemByName(listName)
	local scrollPointer = ruserdata(menuData) + 0x110
	return rdword(scrollPointer, scroll)
end

function setListScroll(listName, scroll)
	local menuData = Infinity_FindUIItemByName(listName)
	local scrollPointer = ruserdata(menuData) + 0x110
	wdword(scrollPointer, scroll)
end

function storeTemplateInstance(templateName, instanceID, storeIntoName)

	local stringAddress = malloc(#templateName + 0x1)
	wstring(stringAddress, templateName)

	local eax = nil
	local ebx = nil
	local ecx = nil
	local esi = nil
	local edi = nil

	esi = ruserdata(nameToItem[templateName])
	if esi == 0x0 then goto _fail end

	esi = rdword(esi + 0x4)
	edi = 0x0
	esi = rdword(esi + 0x1C)
	if esi == 0x0 then goto _fail end

	::_0x75B4B1::
	eax = rdword(esi + 0x10)
	ebx = rdword(esi + 0x22C)
	if eax == 0x0 then goto _0x75B500 end

	eax = call(0x85B93B, {eax, stringAddress}, nil, 0x8)
	if eax ~= 0x0 then goto _0x75B500 end

	eax = instanceID
	if rdword(esi + 0xC) ~= eax then goto _0x75B500 end

	eax = rdword(esi + 0x22C)
	if edi == 0x0 then goto _0x75B4E6 end

	--wdword(edi + 0x22C, eax)

	::_0x75B4E6::
	ecx = rdword(esi + 0x4)
	if esi ~= rdword(ecx + 0x1C) then goto _0x75B4F5 end
	if eax == 0x0 then goto _0x75B4F5 end

	--wdword(ecx + 0x1C, eax)

	::_0x75B4F5::
	nameToItem[storeIntoName] = tolightuserdata(esi)

	--call(0x85AD13, {esi}, nil, 0x4)
	goto _0x75B502

	::_0x75B500::
	edi = esi

	::_0x75B502::
	esi = ebx
	if ebx ~= 0x0 then goto _0x75B4B1 end
		
	::_fail::
	free(stringAddress)
end

-------------------------
--  ActorID Retrieval  --
-------------------------

function _getActorDataAddress(actorID)
	local resultBlock = malloc(0x4)
	call(0x625C00, {resultBlock, actorID}, nil, 0x8)
	local result = rdword(resultBlock)
	free(resultBlock)
	return result
end

function getActorIDCursor()
	local esi = rdword(0x93FDBC)
	local ecx = rdword(esi + 0xD14)
	local eax = rbyte(ecx + 0x3DA0, 0x0)
	eax = rdword(ecx + eax * 4 + 0x3DA4)
	Infinity_DisplayString(toHex(eax + 0x21C))
	eax = rdword(eax + 0x21C)
	if eax ~= -0x1 then
		return eax
	else
		return 0x0
	end
end

function getActorIDLoaded()
	local ids = {}
	local eax = _getActorDataAddress(0x0)
	local ecx = eax
	eax = rdword(eax)
	eax = call(rdword(eax + 0x1C), {}, ecx, 0x0)
	ebx = rdword(eax)
	repeat
		local actorID = rdword(ebx + 0x8)
		if rdword(_getActorDataAddress(actorID)) == 0x8A86D0 then
			table.insert(ids, actorID)
		end
		ebx = rdword(ebx)
	until ebx == 0x0
	return ids
end

function getActorIDPortrait(slot)
	return call(0x5028D0, {slot}, rdword(rdword(0x93FDBC) + 0xD14), 0x0)
end

function getActorIDSelected()
	local temp = rdword(rdword(rdword(0x93FDBC) + 0xD14) + 0x3E54)
	if temp ~= 0x0 then
		return rdword(temp + 0x8)
	else
		return 0x0
	end
end

------------------------------
--  Actionbar Manipulation  --
------------------------------

function setActionbarConfig(actionbarConfig)
	local eax = rdword(0x93FDBC)
	local ecx = rdword(eax + 0xD14)
	eax = rbyte(ecx + 0x3DA0, 0)
	eax = rdword(ecx + eax * 4 + 0x3DA4)
	eax = rdword(eax + 0x204)
	ecx = eax + 0x2654
	call(0x618160, {actionbarConfig}, ecx, 0x0)
	--0x615CC0
end

ACTIONBAR_TYPE = {
	["BARD_SONG"] = 2,
	["CAST_SPELL"] = 3,
	["FIND_TRAPS"] = 4,
	["TALK"] = 5,
	["GUARD"] = 7,
	["ATTACK"] = 8,
	["SPECIAL_ABILITIES"] = 10,
	["STEALTH"] = 11,
	["THIEVING"] = 12,
	["TURN_UNDEAD"] = 13,
	["USE_ITEM"] = 14,
	["STOP"] = 15,
	["QUICK_ITEM_1"] = 21,
	["QUICK_ITEM_2"] = 22,
	["QUICK_ITEM_3"] = 23,
	["QUICK_SPELL_1"] = 24,
	["QUICK_SPELL_2"] = 25,
	["QUICK_SPELL_3"] = 26,
	["QUICK_WEAPON_1"] = 27,
	["QUICK_WEAPON_2"] = 28,
	["QUICK_WEAPON_3"] = 29,
	["QUICK_WEAPON_4"] = 30,
	["NONE"] = 100,
}

function setActionbarButton(buttonIndex, buttonType)
	if buttonIndex < 0 or buttonIndex > 11 then
		error("buttonIndex out of bounds", 2)
	end
	local ecx = rdword(rdword(0x93FDBC) + 0xD14)
	local actionbarAddress = rdword(rdword(ecx + rbyte(ecx + 0x3DA0, 0) * 4 + 0x3DA4) + 0x204) + 0x2654
	wdword(actionbarAddress + 0x1440 + buttonIndex * 0x4, buttonType)
end

---------------------------
--  Actor Spell Details  --
---------------------------

function _getSpellDescription(resrefLocation)
	local eax = call(0x77D9A0, {0x0, 0x3EE, resrefLocation}, nil, 0xC)
	return Infinity_FetchString(rdword(rdword(eax + 0x40) + 0x50))
end

function _getSpellIcon(resrefLocation)
	local eax = call(0x77D9A0, {0x0, 0x3EE, resrefLocation}, nil, 0xC)
	return rstring(rdword(eax + 0x40) + 0x3A)
end

function _getSpellName(resrefLocation)
	local eax = call(0x77D9A0, {0x0, 0x3EE, resrefLocation}, nil, 0xC)
	local step1 = rdword(eax + 0x40)
	if step1 ~= 0x0 then
		return Infinity_FetchString(rdword(step1 + 0x8))
	else
		return ""
	end
end

function _processKnownClericSpells(actorID, func)
	local eax = nil
	local ebx = _getActorDataAddress(actorID) + 0x690
	local ecx = nil
	local esi = nil
	local edi = 0x0

	local ebp_0xFC = nil
	local ebp_0x104 = ebx
	local ebp_0x10C = edi
	local ebp_0x118 = nil
	local ebp_0x11C = nil

	local cmpTemp = nil

	::_0x7096F0::
	esi = 0x0
	ebp_0x11C = esi
	if rdword(ebx) <= esi then goto _0x7098FA end

	eax = ebx - 0xC

	::_0x709715::
	ecx = eax
	eax = call(0x613B40, {esi}, ecx, 0x0)

	if eax == 0x0 then goto _0x709724 end

	eax = rdword(eax + 0x8)
	func(eax)

	::_0x709724::
	eax = ebp_0x104
	edi = 0x0
	ebx = 0x0
	ebp_0x118 = edi
	esi = 0x0
	if rdword(eax + 0x220) <= ebx then goto _0x709832 end

	eax = eax + 0x214
	ebp_0xFC = eax

	::_0x7097D4::
	ecx = eax
	eax = call(0x613B40, {esi}, ecx, 0x0)
	if eax ~= 0x0 then goto _0x7097E4 end

	edi = 0x0
	goto _0x7097E7

	::_0x7097E4::
	edi = rdword(eax + 0x8)

	::_0x7097E7::
	ebp_0x118 = ebp_0x118 + 1
	if bit32.band(rbyte(edi + 0x8, 0x0), 0x1) == 0x0 then goto _0x709817 end

	ebx = ebx + 1

	::_0x709817::
	eax = ebp_0x104
	esi = esi + 1
	cmpTemp = rdword(eax + 0x220)
	eax = ebp_0xFC
	if esi < cmpTemp then goto _0x7097D4 end

	edi = ebp_0x118

	::_0x709832::
	esi = ebp_0x11C
	esi = esi + 0x1
	ebp_0x11C = esi

	::_0x7098DC::
	ebx = ebp_0x104
	eax = ebx - 0xC
	if esi < rdword(ebx) then goto _0x709715 end

	edi = ebp_0x10C

	::_0x7098FA::
	edi = edi + 0x1
	ebp_0x10C = edi
	ebx = ebx + 0x1C
	ebp_0x104 = ebx
	if edi < 0x7 then goto _0x7096F0 end
end

function _processKnownWizardSpells(actorID, func)
	local eax = nil
	local ebx = _getActorDataAddress(actorID) + 0x754
	local ecx = nil
	local esi = nil
	local edi = 0x0

	local ebp_0xFC = nil
	local ebp_0x104 = ebx
	local ebp_0x10C = edi
	local ebp_0x118 = nil
	local ebp_0x11C = nil

	local cmpTemp = nil

	::_0x7096F0::
	esi = 0x0
	ebp_0x11C = esi
	if rdword(ebx) <= esi then goto _0x7098FA end

	eax = ebx - 0xC

	::_0x709715::
	ecx = eax
	eax = call(0x613B40, {esi}, ecx, 0x0)

	if eax == 0x0 then goto _0x709724 end

	eax = rdword(eax + 0x8)
	func(eax)

	::_0x709724::
	eax = ebp_0x104
	edi = 0x0
	ebx = 0x0
	ebp_0x118 = edi
	esi = 0x0
	if rdword(eax + 0x220) <= ebx then goto _0x709832 end

	eax = eax + 0x214
	ebp_0xFC = eax

	::_0x7097D4::
	ecx = eax
	eax = call(0x613B40, {esi}, ecx, 0x0)
	if eax ~= 0x0 then goto _0x7097E4 end

	edi = 0x0
	goto _0x7097E7

	::_0x7097E4::
	edi = rdword(eax + 0x8)

	::_0x7097E7::
	ebp_0x118 = ebp_0x118 + 1
	if bit32.band(rbyte(edi + 0x8, 0x0), 0x1) == 0x0 then goto _0x709817 end

	ebx = ebx + 1

	::_0x709817::
	eax = ebp_0x104
	esi = esi + 1
	cmpTemp = rdword(eax + 0x220)
	eax = ebp_0xFC
	if esi < cmpTemp then goto _0x7097D4 end

	edi = ebp_0x118

	::_0x709832::
	esi = ebp_0x11C
	esi = esi + 0x1
	ebp_0x11C = esi

	::_0x7098DC::
	ebx = ebp_0x104
	eax = ebx - 0xC
	if esi < rdword(ebx) then goto _0x709715 end

	edi = ebp_0x10C

	::_0x7098FA::
	edi = edi + 0x1
	ebp_0x10C = edi
	ebx = ebx + 0x1C
	ebp_0x104 = ebx
	if edi < 0x9 then goto _0x7096F0 end
end

function _processKnownInnateSpells(actorID, func)
	local eax = nil
	local ebx = _getActorDataAddress(actorID) + 0x850
	local ecx = nil
	local esi = nil
	local edi = 0x0

	local ebp_0xFC = nil
	local ebp_0x104 = ebx
	local ebp_0x10C = edi
	local ebp_0x118 = nil
	local ebp_0x11C = nil

	local cmpTemp = nil

	::_0x7096F0::
	esi = 0x0
	ebp_0x11C = esi
	if rdword(ebx) <= esi then goto _0x7098FA end

	eax = ebx - 0xC

	::_0x709715::
	ecx = eax
	eax = call(0x613B40, {esi}, ecx, 0x0)

	if eax == 0x0 then goto _0x709724 end

	eax = rdword(eax + 0x8)
	func(eax)

	::_0x709724::
	eax = ebp_0x104
	edi = 0x0
	ebx = 0x0
	ebp_0x118 = edi
	esi = 0x0
	if rdword(eax + 0x220) <= ebx then goto _0x709832 end

	eax = eax + 0x214
	ebp_0xFC = eax

	::_0x7097D4::
	ecx = eax
	eax = call(0x613B40, {esi}, ecx, 0x0)
	if eax ~= 0x0 then goto _0x7097E4 end

	edi = 0x0
	goto _0x7097E7

	::_0x7097E4::
	edi = rdword(eax + 0x8)

	::_0x7097E7::
	ebp_0x118 = ebp_0x118 + 1
	if bit32.band(rbyte(edi + 0x8, 0x0), 0x1) == 0x0 then goto _0x709817 end

	ebx = ebx + 1

	::_0x709817::
	eax = ebp_0x104
	esi = esi + 1
	cmpTemp = rdword(eax + 0x220)
	eax = ebp_0xFC
	if esi < cmpTemp then goto _0x7097D4 end

	edi = ebp_0x118

	::_0x709832::
	esi = ebp_0x11C
	esi = esi + 0x1
	ebp_0x11C = esi

	::_0x7098DC::
	ebx = ebp_0x104
	eax = ebx - 0xC
	if esi < rdword(ebx) then goto _0x709715 end

	edi = ebp_0x10C

	::_0x7098FA::
	edi = edi + 0x1
	ebp_0x10C = edi
	ebx = ebx + 0x1C
	ebp_0x104 = ebx
	if edi < 0x1 then goto _0x7096F0 end
end

function _processClericMemorization(actorID, func)
	local info = {}
	local infoIndex = nil
	local maxLevel = 0x7
	local ebx = maxLevel
	local esi = ebx
	local ecx = ebx
	local edi = _getActorDataAddress(actorID)
	local edx = rdword(edi + 0x12DA)
	ecx = ecx * 0x16
	edx = edx + ecx
	ecx = ebx * 0x8
	ecx = ecx - ebx
	ecx = ecx + 0x223
	local eax = 0x0
	ecx = edi + ecx * 0x4
	::_0::
	if eax >= maxLevel then goto _3 end

	table.insert(info, 1, {})

	eax = rdword(ecx)
	if eax == 0x0 then goto _2 end
	::_1::
	esi = rdword(eax + 0x8)

	infoIndex = #info[1] + 1
	info[1][infoIndex] = {}
	info[1][infoIndex].address = esi

	eax = rdword(eax)
	if eax ~= 0x0 then goto _1 end
	::_2::
	ebx = ebx - 1
	ecx = ecx - 0x1C
	edx = edx - 0x10
	if ebx > 0 then goto _0 end
	::_3::
	for level = 1, #info, 1 do
		local addresses = info[level]
		for i = 1, #addresses, 1 do
			func(level, addresses[i].address)
		end
	end
end

function _processWizardMemorization(actorID, func)
	local info = {}
	local infoIndex = nil
	local maxLevel = 0x9
	local ebx = maxLevel
	local esi = ebx
	local ecx = ebx
	local edi = _getActorDataAddress(actorID)
	local edx = rdword(edi + 0x124A)
	ecx = ecx * 0x16
	edx = edx + ecx
	ecx = ebx * 0x8
	ecx = ecx - ebx
	ecx = ecx + 0x254
	local eax = 0x0
	ecx = edi + ecx * 0x4

	::_0::
	if eax >= maxLevel then goto _3 end

	table.insert(info, 1, {})

	eax = rdword(ecx)
	if eax == 0x0 then goto _2 end

	::_1::
	esi = rdword(eax + 0x8)

	infoIndex = #info[1] + 1
	info[1][infoIndex] = {}
	info[1][infoIndex].address = esi

	eax = rdword(eax)
	if eax ~= 0x0 then goto _1 end

	::_2::
	ebx = ebx - 1
	ecx = ecx - 0x1C
	edx = edx - 0x10
	if ebx > 0 then goto _0 end

	::_3::
	for level = 1, #info, 1 do
		local addresses = info[level]
		for i = 1, #addresses, 1 do
			func(level, addresses[i].address)
		end
	end
end

function _processInnateMemorization(actorID, func)
	local resrefLocation = nil
	local currentAddress = rdword(_getActorDataAddress(actorID) + 0xA68)

	::_0::
	if currentAddress == 0x0 then goto _1 end 
	resrefLocation = rdword(currentAddress + 0x8)
	func(0x1, resrefLocation)
	currentAddress = rdword(currentAddress)
	goto _0

	::_1::
end

function getMemorizedClericSpells(actorID)
	local toReturn = {}
	for i = 1, 7, 1 do
		table.insert(toReturn, {})
	end
	_processClericMemorization(actorID, 
		function(level, resrefLocation) 
			local memorizedSpell = {}
			memorizedSpell.resref = rstring(resrefLocation)
			memorizedSpell.icon = _getSpellIcon(resrefLocation)
			local flags = rword(resrefLocation + 0x8, 0x0)
			memorizedSpell.castable = isBitUnset(flags, 0x0)
			memorizedSpell.index = #toReturn[level]
			table.insert(toReturn[level], memorizedSpell)
		end
	)
	return toReturn
end

function getMemorizedWizardSpells(actorID)
	local toReturn = {}
	for i = 1, 9, 1 do
		table.insert(toReturn, {})
	end
	_processWizardMemorization(actorID, 
		function(level, resrefLocation) 
			local memorizedSpell = {}
			memorizedSpell.resref = rstring(resrefLocation)
			memorizedSpell.icon = _getSpellIcon(resrefLocation)
			local flags = rword(resrefLocation + 0x8, 0x0)
			memorizedSpell.castable = isBitUnset(flags, 0x0)
			memorizedSpell.index = #toReturn[level]
			table.insert(toReturn[level], memorizedSpell)
		end
	)
	return toReturn
end

function getMemorizedInnateSpells(actorID)
	local toReturn = {}
	table.insert(toReturn, {})
	_processInnateMemorization(actorID, 
		function(level, resrefLocation) 
			local memorizedSpell = {}
			memorizedSpell.resref = rstring(resrefLocation)
			memorizedSpell.icon = _getSpellIcon(resrefLocation)
			local flags = rword(resrefLocation + 0x8, 0x0)
			memorizedSpell.castable = isBitUnset(flags, 0x0)
			memorizedSpell.index = #toReturn[level]
			table.insert(toReturn[level], memorizedSpell)
		end
	)
	return toReturn
end

function getKnownClericSpells(actorID)
	local toReturn = {}
	for i = 1, 7, 1 do
		table.insert(toReturn, {})
	end
	_processKnownClericSpells(actorID, 
		function(resrefLocation) 
			local level = rword(resrefLocation + 0x8, 0x0) + 1
			local knownSpell = {}
			knownSpell.resref = rstring(resrefLocation)
			knownSpell.icon = _getSpellIcon(resrefLocation)
			knownSpell.name = _getSpellName(resrefLocation)
			knownSpell.description = _getSpellDescription(resrefLocation)
			knownSpell.index = #toReturn[level]
			table.insert(toReturn[level], knownSpell)
		end
	)
	return toReturn
end

function getKnownWizardSpells(actorID)
	local toReturn = {}
	for i = 1, 9, 1 do
		table.insert(toReturn, {})
	end
	_processKnownWizardSpells(actorID, 
		function(resrefLocation) 
			local level = rword(resrefLocation + 0x8, 0x0) + 1
			local knownSpell = {}
			knownSpell.resref = rstring(resrefLocation)
			knownSpell.icon = _getSpellIcon(resrefLocation)
			knownSpell.name = _getSpellName(resrefLocation)
			knownSpell.description = _getSpellDescription(resrefLocation)
			knownSpell.index = #toReturn[level]
			table.insert(toReturn[level], knownSpell)
		end
	)
	return toReturn
end

function getKnownInnateSpells(actorID)
	local toReturn = {}
	table.insert(toReturn, {})
	_processKnownInnateSpells(actorID, 
		function(resrefLocation) 
			local level = rword(resrefLocation + 0x8, 0x0) + 1
			local knownSpell = {}
			knownSpell.resref = rstring(resrefLocation)
			knownSpell.icon = _getSpellIcon(resrefLocation)
			knownSpell.name = _getSpellName(resrefLocation)
			knownSpell.description = _getSpellDescription(resrefLocation)
			knownSpell.index = #toReturn[level]
			table.insert(toReturn[level], knownSpell)
		end
	)
	return toReturn
end

---------------------
--  Actor Details  --
---------------------

function getActorAlignment(actorID)
	return rbyte(_getActorDataAddress(actorID) + 0x30, 0x3)
end

function getActorAllegiance(actorID)
	return rbyte(_getActorDataAddress(actorID) + 0x24, 0x0)
end

function getActorClass(actorID)
	return rbyte(_getActorDataAddress(actorID) + 0x24, 0x3)
end

function getActorGender(actorID)
	return rbyte(_getActorDataAddress(actorID) + 0x30, 0x2)
end

function getActorGeneral(actorID)
	return rbyte(_getActorDataAddress(actorID) + 0x24, 0x1)
end

function getActorRace(actorID)
	return rbyte(_getActorDataAddress(actorID) + 0x24, 0x2)
end

function getActorSpecific(actorID)
	return rbyte(_getActorDataAddress(actorID) + 0x30, 0x1)
end

function getActorKit(actorID)
	return call(0x53A7A0, {}, _getActorDataAddress(actorID), 0x0)
end

function getActorAreaSize(actorID)
	local address = rdword(_getActorDataAddress(actorID) + 0x14)
	local width = rword(address + 0x4BC, 0x0) * 64
	local height = rword(address + 0x4C0, 0x0) * 64
	return width, height
end

function getActorEffectResrefs(actorID)
	local uniqueList = {}
	local resref = nil

	local esi = rdword(_getActorDataAddress(actorID) + 0x33AC)
	if esi == 0x0 then goto _fail end

	::_loop::
	edi = rdword(esi + 0x8) + 0x90

	resref = rstring(edi)
	if #resref > 0 then
		local spellName = _getSpellName(edi)
		if spellName ~= "" then
			local value = {}
			value.name = spellName
			value.icon = _getSpellIcon(edi)
			uniqueList[resref] = value
		end
	end

	esi = rdword(esi)
	if esi ~= 0x0 then goto _loop end

	::_fail::
	local toReturn = {}
	for resref, uniqueValue in pairs(uniqueList) do
		value = {}
		value.resref = resref
		value.name = uniqueValue.name
		value.icon = uniqueValue.icon
		table.insert(toReturn, value)
	end
	return toReturn
end

function getActorLocation(actorID)
	local dataAddress = _getActorDataAddress(actorID)
	local x = rdword(dataAddress + 0x8)
	local y = rdword(dataAddress + 0xC)
	return x, y
end

function getActorModalTimer(actorID)
	local actorData = _getActorDataAddress(actorID)
	local idRemainder = actorID % 0x64
	local modalTimer = rdword(actorData + 0x2C4)
	local timerRemainder = modalTimer % 0x64
	if timerRemainder < idRemainder then
		return idRemainder - timerRemainder
	else
		return 100 - timerRemainder + idRemainder
	end
end

function getActorName(actorID)
	return rstring(rdword(call(0x6E7220, {0x0}, _getActorDataAddress(actorID), 0x0)))
end

function getActorScriptName(actorID)
	local dataAddress = _getActorDataAddress(actorID)
	return rstring(rdword(call(rdword(rdword(dataAddress) + 0x10), {}, dataAddress, 0x0)))
end

function getActorSpellState(actorID, splstateID)
	return call(0x52DF30, {splstateID}, _getActorDataAddress(actorID) + 0xB30, 0x0) == 1
end

function getActorSpellTimer(actorID)
	return rdword(_getActorDataAddress(actorID) + 0x3870)
end

function getActorStat(actorID, statID)
	local ecx = call(0x4FE120, {}, _getActorDataAddress(actorID), 0x0)
	return call(0x52CC40, {statID}, ecx, 0x0)
end

----------------------
--  Spell Learning  --
----------------------

function learnWizardSpell(actorID, level, resref)
	local resrefAddress = malloc(0xC)
	wstring(resrefAddress, resref)
	call(0x6D9DC0, {level, resrefAddress}, _getActorDataAddress(actorID), 0x0)
	free(resrefAddress)
end

function learnClericSpell(actorID, level, resref)
	local actorDataAddress = _getActorDataAddress(actorID)
	local spellLevelListPointer = actorDataAddress + (level * 8 - level + 0x1A1) * 4
	local resrefAddress = malloc(0xC)
	wstring(resrefAddress, resref)
	call(0x6D9B40, {0x0, spellLevelListPointer, level, resrefAddress}, actorDataAddress, 0x0)
	free(resrefAddress)
end

function learnInnateSpell(actorID, resref)
	local actorDataAddress = _getActorDataAddress(actorID)
	local spellLevelListPointer = actorDataAddress + 0x844
	local resrefAddress = malloc(0xC)
	wstring(resrefAddress, resref)
	call(0x6D9B40, {0x2, spellLevelListPointer, 0x0, resrefAddress}, actorDataAddress, 0x0)
	free(resrefAddress)
end

function unlearnWizardSpell(actorID, level, resref)
	local actorDataAddress = _getActorDataAddress(actorID)
	local resrefAddress = malloc(0xC)
	wstring(resrefAddress, resref)
	call(0x6F7E00, {level, resrefAddress}, actorDataAddress, 0x0) 
	free(resrefAddress)
end

function unlearnClericSpell(actorID, level, resref)
	local actorDataAddress = _getActorDataAddress(actorID)
	local resrefAddress = malloc(0xC)
	wstring(resrefAddress, resref)
	call(0x6F7E30, {level, resrefAddress}, actorDataAddress, 0x0) 
	free(resrefAddress)
end

function unlearnInnateSpell(actorID, resref)
	local actorDataAddress = _getActorDataAddress(actorID)
	local spellLevelListPointer = actorDataAddress + 0x844
	local resrefAddress = malloc(0xC)
	wstring(resrefAddress, resref)
	call(0x6F7D40, {spellLevelListPointer, resrefAddress}, actorDataAddress, 0x0) 
	free(resrefAddress)
end

--------------------------
--  Spell Memorization  --
--------------------------

function getMaximumMemorizableWizardSpells(actorID, level)
	local esi = _getActorDataAddress(actorID)
	local ecx = esi + 0xB30
	if rdword(esi + 0x3748) ~= 0x0 then goto _0 end
	ecx = esi + 0x1454
	::_0::
	local edx = level
	local eax = edx
	eax = eax * 0x10
	eax = eax + 0x728
	eax = eax + ecx
	return rword(eax, 0x1)
end

function getMaximumMemorizableClericSpells(actorID, level)
	local esi = _getActorDataAddress(actorID)
	local ecx = esi + 0xB30
	if rdword(esi + 0x3748) ~= 0x0 then goto _0 end
	ecx = esi + 0x1454
	::_0::
	local edx = level
	local eax = edx
	eax = eax * 0x10
	eax = eax + 0x7B8
	eax = eax + ecx
	return rword(eax, 0x1)
end

function getMaximumMemorizableInnateSpells(actorID)
	return rword(rdword(_getActorDataAddress(actorID) + 0x8A0), 0x1)
end

function memorizeWizardSpell(actorID, level, resref)
	local esi = _getActorDataAddress(actorID)
	local ecx = esi + 0xB30
	if rdword(esi + 0x3748) ~= 0x0 then goto _0 end
	ecx = esi + 0x1454
	::_0::
	local edx = level
	local eax = edx
	eax = eax * 0x10
	eax = eax + 0x728
	eax = eax + ecx
	local upperBoundPointer = eax
	local incrementMemorizedPointer = rdword(esi + edx * 0x4 + 0x87C)
	ecx = edx + 0x56
	eax = ecx * 0x8
	eax = eax - ecx
	ecx = esi
	eax = esi + eax * 0x4
	local currentlyMemorizedPointer = eax
	eax = edx * 0x8
	eax = eax - edx
	eax = eax + 0x1D2
	eax = esi + eax * 0x4

	local spellLevelListPointer = malloc(0x14)
	wdword(spellLevelListPointer, spellLevelListPointer + 0x8)
	wdword(spellLevelListPointer + 0x4, spellLevelListPointer - 0x8)
	wstring(spellLevelListPointer + 0x8, resref)
	local insertedIndexAddress = spellLevelListPointer + 0x11

	call(0x6F1390, {upperBoundPointer, incrementMemorizedPointer, 
		currentlyMemorizedPointer, spellLevelListPointer, 
		insertedIndexAddress, 0x0}, esi, 0x0)

	free(spellLevelListPointer)
end

function memorizeClericSpell(actorID, level, resref)
	local esi = _getActorDataAddress(actorID)
	local ecx = esi + 0xB30
	if rdword(esi + 0x3748) ~= 0x0 then goto _0 end
	ecx = esi + 0x1454
	::_0::
	local edx = level
	local eax = edx
	eax = eax * 0x10
	eax = eax + 0x7B8
	eax = eax + ecx
	local upperBoundPointer = eax
	local incrementMemorizedPointer = rdword(esi + edx * 0x4 + 0x860)
	ecx = edx + 0x4F
	eax = ecx * 0x8
	eax = eax - ecx
	ecx = esi
	eax = esi + eax * 0x4
	local currentlyMemorizedPointer = eax
	eax = edx * 0x8
	eax = eax - edx
	eax = eax + 0x1A1
	eax = esi + eax * 0x4

	local spellLevelListPointer = malloc(0x14)
	wdword(spellLevelListPointer, spellLevelListPointer + 0x8)
	wdword(spellLevelListPointer + 0x4, spellLevelListPointer - 0x8)
	wstring(spellLevelListPointer + 0x8, resref)
	local insertedIndexAddress = spellLevelListPointer + 0x11

	call(0x6F1390, {upperBoundPointer, incrementMemorizedPointer, 
		currentlyMemorizedPointer, spellLevelListPointer, 
		insertedIndexAddress, 0x0}, esi, 0x0)

	free(spellLevelListPointer)
end

function memorizeInnateSpell(actorID, resref)
	local ecx = _getActorDataAddress(actorID)
	local esi = 0x0
	local eax = rdword(ecx + esi * 0x4 + 0x8A0)
	local edx = esi + 0x5F
	local upperBoundPointer = eax
	local incrementMemorizedPointer =  eax
	eax = edx * 0x8
	eax = eax - edx
	eax = ecx + eax * 0x4
	local currentlyMemorizedPointer = eax

	local spellLevelListPointer = malloc(0x14)
	wdword(spellLevelListPointer, spellLevelListPointer + 0x8)
	wdword(spellLevelListPointer + 0x4, spellLevelListPointer - 0x8)
	wstring(spellLevelListPointer + 0x8, resref)
	local insertedIndexAddress = spellLevelListPointer + 0x11

	call(0x6F1390, {upperBoundPointer, incrementMemorizedPointer, 
		currentlyMemorizedPointer, spellLevelListPointer, 
		insertedIndexAddress, 0x0}, ecx, 0x0)

	free(spellLevelListPointer)
end

function unmemorizeWizardSpell(actorID, level, index)
	call(0x708370, {index, level}, _getActorDataAddress(actorID), 0x0)
end

function unmemorizeClericSpell(actorID, level, index)
	call(0x7083D0, {index, level}, _getActorDataAddress(actorID), 0x0)
end

function unmemorizeInnateSpell(actorID, index)
	local actorDataAddress = _getActorDataAddress(actorID)
	local innatesLevel = actorDataAddress + 0xA64
	local eax = call(0x613B40, {index}, innatesLevel, 0x0)
	if eax == 0x0 then goto _0 end
	call(0x780E80, {eax}, innatesLevel, 0x0)
	free(rdword(eax + 0x8))
	local edi = actorDataAddress + 0x8A0 
	wdword(edi, rdword(edi) - 1)
	::_0::
end
