---@class Error
---@field msg string
Error = {}

---@param msg string
---@return Error
function Error.new(msg)
    local instance = {
		msg = msg
	}
	setmetatable(instance, {__index=Error})
    return instance
end

---@class Result: { ok: boolean, v: unknown|Error }
---@field v unknown|Error
---@field isOk boolean
Result = {}

---@param value unknown
---@return Result
function Result.ok(value)
	---@type Result
	local instance = {
		isOk=true,
		v=value
	}
	setmetatable(instance, {__index=Result})
    return instance
end

---@param value string
---@return Result
function Result.err(value)
	---@type Result
	local instance = {
		isOk=false,
		v=Error.new(value)
	}
	setmetatable(instance, {__index=Result})
    return instance
end

---@return Error
function Result:asError()
	return self.v --[[@as Error]]
end

---@generic T
---@return T
function Result:asOK()
	return self.v
end

---@alias Slot {name:string, count:number}

---@class Inventory
---@field protected accessor function
---@field protected peripheral table
Inventory = {
	DEFAULT_SIZE = 27
}

---@alias Peripheral table

---Constructor
---@param peripheral Peripheral
---@return Inventory|nil
function Inventory.new(peripheral)
    local instance = {
		peripheral=peripheral
	}

	if type(peripheral.list) == "function" then
		instance.accessor = peripheral.list
	else
		return nil
	end

	setmetatable(instance, {__index=Inventory})
    return instance
end

---
---@param filter string
---@return number
function Inventory:count(filter)
    local sum = 0
	local contents = self.accessor()
    for _,v in pairs(contents) do
		if (filter == nil or v.name == filter) then
			sum = sum + v.count
		end
    end
    return sum
end

---Finds an item in an inventory
---@param name string
---@return number|nil slot Slot number, nil if not found
---@return table|nil item Full item table
function Inventory:find(name)
	local contents = self.accessor()
    for i,v in pairs(contents) do
        if (v.name == name) then
            return i,v
        end
    end
end

---Checks if the full item tally is 0
---@return boolean
function Inventory:isEmpty()
	local contents = self.accessor()
	for _,v in pairs(contents) do
		if v.count > 0 then
			return false
		end
	end

	return true
end

---Tally up the total number of items in every stack for each kind of item
---@return {[string]: number}
function Inventory:tally()
	local tally = {}
	local contents = self.accessor()
	for _,v in pairs(contents) do
		if tally[v.name] then
			tally[v.name] = tally[v.name] + v.count
		else
			tally[v.name] = v.count
		end
	end

	return tally
end

Time = {}
Crypto = {}
Debug = {
	levels = {
		[1] = "[FATAL] ",
		[2] = "[error] ",
		[3] = "[warning] ",
		[4] = "[info] ",
		[5] = "[debug] ",
		[6] = "",
		[7] = "",
		[8] = "",
		[9] = "",
	},
	colors = {
		[1] = {colors.black,  colors.red},
		[2] = {colors.red,    nil},
		[3] = {colors.orange, nil},
		[4] = {colors.yellow, nil},
		[5] = {colors.lightBlue,  nil},
		[6] = {colors.white,  nil},
		[7] = {colors.white,  nil},
		[8] = {colors.white,  nil},
		[9] = {colors.white,  nil},
	}
}

local sides = {
	"top", "bottom", "left", "right", "front", "back"
}

function Debug.log(str, n, level)
	local old_bg
	if not level then
		level = 5
	end

	if Debug.colors[level] and Debug.colors[level][2] then
		old_bg = term.getBackgroundColor()
		term.setBackgroundColor(Debug.colors[level][2])
	end

    if n ~= nil then 
        term.setCursorPos(1, n)
        term.clearLine()
    end

    local old_ctxt = term.getBackgroundColor()
    term.setTextColor(Debug.colors[level][1])
    term.write(string.format("[%0.2f]%s", os.clock(), Debug.levels[level]))
    print(str)
    term.setTextColor(old_ctxt)

    if old_bg then
    	term.setBackgroundColor(old_bg)
    end
end

function Debug.fatal(str, n)
	return Debug.log(str, n, 1)
end
function Debug.fatalf(format, str, ...)
	return Debug.fatal(string.format(format, str, ...))
end

function Debug.error(str, n)
	return Debug.log(str, n, 2)
end
function Debug.errorf(format, str, ...)
	return Debug.error(string.format(format, str, ...))
end
function Debug.warning(str, n)
	return Debug.log(str, n, 3)
end
Debug.warn = Debug.warning
function Debug.warningf(format, str, ...)
	return Debug.warning(string.format(format, str, ...))
end
function Debug.info(str, n)
	return Debug.log(str, n, 4)
end
function Debug.infof(format, str, ...)
	return Debug.info(string.format(format, str, ...))
end
function Debug.debug(str, n)
	return Debug.log(str, n, 5)
end
function Debug.debugf(format, str, ...)
	return Debug.debug(string.format(format, str, ...))
end

function redstone.pulse(side, time)
	redstone.setOutput(side, true)
	sleep(time/2)
	redstone.setOutput(side, false)
	sleep(time/2)
end

local __rs_old = {}

__rs_old.setOutput = redstone.setOutput
function redstone.setOutput(side, bool)
	if side ~= "all" then
		return __rs_old.setOutput(side, bool)
	end

	for i,v in pairs(sides) do
		__rs_old.setOutput(v, bool)
	end
end

function table.length(t)
	local sum = 0
	for i,v in pairs(t) do
		sum = sum + 1
	end
	return sum
end

function table.map(t, func)
	local r = {}
	for i,v in pairs(t) do
		r[i] = func(v,i)
	end
	return r
end

--- Calls the `closure` function passed as parameter for each element of `t` with `t`'s values
--- and indices as passed parameters 1 and 2, and returns a new table without the elements for
--- which the result of `closure(value, key)` returned `false`. If the closure crashes, `filter`
--- crashes too.
---@param t table
---@param closure function
local function filter(t, closure)
	local r = {}
	for i,v in pairs(t) do
		local worked, result = pcall(closure, v, i)

		if not worked then
			error("Crash in the closure function " .. tostring(closure) .. ". " .. result)
		elseif result then
			r[i] = v
		end
	end
	return r
end
table.filter = filter

---Merge `t1`'s and `t2`'s indices into a new table
---
---if `t1` and `t2` both have an index in common, elements of `t1` take priority
---@param t1 table
---@param t2 table
---@return table t3
function table.union(t1, t2)
	local t3 = {}
	for i,v in pairs(t1) do
		t3[i] = v
	end
	for i,v in pairs(t2) do
		if (not t3[i]) then
			t3[i] = v
		end
	end

	return t3
end

---Returns a table containing the indices present in either `t1` or `t2` but not both.
---
---Does not care about values.
---
---> ```lua
---> table.diff({foo=1, bar=2}, {bar=5, baz=3})
---> >{foo=1,baz=3}
---> -- bar having two different values is not checked. Only indices matter.
---> ```
---@param t1 table
---@param t2 table
---@return table
function table.diff(t1, t2)
	local t3 = {}
	for i,v in pairs(t1) do
		if (not t2[i]) then
			t3[i] = v
		end
	end
	for i,v in pairs(t2) do
		if (not t1[i] and not t3[i]) then
			t3[i] = v
		end
	end

	return t3
end

--- Will compare the table's values against `value` if `value` is of a primitive type. If `value` is a table, a function, or userdata, `table.contains` will only compare their reference. `table.contains` does not handle recursiveness.
---@param t table
---@param value any
---@return boolean
function table.contains(t, value)
	for _,v in pairs(t) do
		if v == value then
			return true
		end
	end

	return false
end

local oldGetName = peripheral.getNames
---`peripheral.getNames()` but with a filter argument that checks each peripheral's type against this value and only returns the matches
---@param peripheralType string|nil
local function getNamesFiltered(peripheralType)
	if not peripheralType then return oldGetName() end

	local ret = {}
    local names = oldGetName()
	if names then
		for _,v in pairs(names) do
			local types = {peripheral.getType(v)}

			if table.contains(types, peripheralType) then
				table.insert(ret, v)
			end
		end
	end

    return ret
end
peripheral.getNames = getNamesFiltered

function printf(format, ...)
    return print(string.format(format, ...))
end

function Time.timestamp()
	local timestamp = nil
	local start_time = os.clock()
	local r = http.get("http://www.google.com")
	if r then
		local h = r.getResponseHeaders()
		if h then
			-- local debug_time = string.sub(h.Date, 18, 19) .. string.sub(h.Date, 21, 22) .. string.sub(h.Date, 24, 25)
			timestamp = 0
			local h_in_s = tonumber(string.sub(h.Date, 18, 19))*3600
			if h_in_s == nil then return end
			local m_in_s = tonumber(string.sub(h.Date, 21, 22))*60
			if m_in_s == nil then return end
			local s_in_s = tonumber(string.sub(h.Date, 24, 25))
			if s_in_s == nil then return end
			timestamp = timestamp + h_in_s
			timestamp = timestamp + m_in_s
			timestamp = timestamp + s_in_s
			timestamp = timestamp - (os.clock()-start_time)

			return timestamp
		end
	end
end

local function crc32()
	--[[	Copyright (C) 2022 SafeteeWoW github.com/SafeteeWoW

	This software is provided 'as-is', without any express or implied
	warranty.  In no event will the authors be held liable for any damages
	arising from the use of this software.

	Permission is granted to anyone to use this software for any purpose,
	including commercial applications, and to alter it and redistribute it
	freely, subject to the following restrictions:

	1. The origin of this software must not be misrepresented; you must not
	   claim that you wrote the original software. If you use this software
	   in a product, an acknowledgment in the product documentation would be
	   appreciated but is not required.
	2. Altered source versions must be plainly marked as such, and must not be
	   misrepresented as being the original software.
	3. This notice may not be removed or altered from any source distribution.
	--]]

	local string_byte = string.byte

	-- Calculate xor for two unsigned 8bit numbers (0 <= a,b <= 255)
	local function Xor8(a, b)
		local ret = 0
		local fact = 128
		while fact > a and fact > b do
			fact = fact / 2
		end
		while fact >= 1 do
	        ret = ret + (((a >= fact or b >= fact)
				and (a < fact or b < fact)) and fact or 0)
	        a = a - ((a >= fact) and fact or 0)
	        b = b - ((b >= fact) and fact or 0)
		    fact = fact / 2
		end
		return ret
	end

	-- table to cache the result of uint8 xor(x, y)  (0<=x,y<=255)
	local _xor8_table

	local function GenerateXorTable()
		assert(not _xor8_table)
		_xor8_table = {}
		for i = 0, 255 do
			local t = {}
			_xor8_table[i] = t
			for j = 0, 255 do
				t[j] = Xor8(i, j)
			end
		end
	end

	local _crc_table0 = {
		[0]=0,150,44,186,25,143,53,163,50,164,30,136,43,189,7,145,100,242,72,222,
		125,235,81,199,86,192,122,236,79,217,99,245,200,94,228,114,209,71,253,107,
		250,108,214,64,227,117,207,89,172,58,128,22,181,35,153,15,158,8,178,36,135,
		17,171,61,144,6,188,42,137,31,165,51,162,52,142,24,187,45,151,1,244,98,216,
		78,237,123,193,87,198,80,234,124,223,73,243,101,88,206,116,226,65,215,109,
		251,106,252,70,208,115,229,95,201,60,170,16,134,37,179,9,159,14,152,34,180,
		23,129,59,173,32,182,12,154,57,175,21,131,18,132,62,168,11,157,39,177,68,
		210,104,254,93,203,113,231,118,224,90,204,111,249,67,213,232,126,196,82,241,
		103,221,75,218,76,246,96,195,85,239,121,140,26,160,54,149,3,185,47,190,
		40,146,4,167,49,139,29,176,38,156,10,169,63,133,19,130,20,174,56,155,13,183,
		33,212,66,248,110,205,91,225,119,230,112,202,92,255,105,211,69,120,238,84,
		194,97,247,77,219,74,220,102,240,83,197,127,233,28,138,48,166,5,147,41,191,
		46,184,2,148,55,161,27,141}
	local _crc_table1 = {
		[0]=0,48,97,81,196,244,165,149,136,184,233,217,76,124,45,29,16,32,113,65,
		212,228,181,133,152,168,249,201,92,108,61,13,32,16,65,113,228,212,133,181,
		168,152,201,249,108,92,13,61,48,0,81,97,244,196,149,165,184,136,217,233,124,
		76,29,45,65,113,32,16,133,181,228,212,201,249,168,152,13,61,108,92,81,97,48,
		0,149,165,244,196,217,233,184,136,29,45,124,76,97,81,0,48,165,149,196,244,
		233,217,136,184,45,29,76,124,113,65,16,32,181,133,212,228,249,201,152,168,
		61,13,92,108,131,179,226,210,71,119,38,22,11,59,106,90,207,255,174,158,147,
		163,242,194,87,103,54,6,27,43,122,74,223,239,190,142,163,147,194,242,103,87,
		6,54,43,27,74,122,239,223,142,190,179,131,210,226,119,71,22,38,59,11,90,106,
		255,207,158,174,194,242,163,147,6,54,103,87,74,122,43,27,142,190,239,223,
		210,226,179,131,22,38,119,71,90,106,59,11,158,174,255,207,226,210,131,179,
		38,22,71,119,106,90,11,59,174,158,207,255,242,194,147,163,54,6,87,103,122,
		74,27,43,190,142,223,239}
	local _crc_table2 = {
		[0]=0,7,14,9,109,106,99,100,219,220,213,210,182,177,184,191,183,176,185,190,
		218,221,212,211,108,107,98,101,1,6,15,8,110,105,96,103,3,4,13,10,181,178,
		187,188,216,223,214,209,217,222,215,208,180,179,186,189,2,5,12,11,111,104,
		97,102,220,219,210,213,177,182,191,184,7,0,9,14,106,109,100,99,107,108,101,
		98,6,1,8,15,176,183,190,185,221,218,211,212,178,181,188,187,223,216,209,214,
		105,110,103,96,4,3,10,13,5,2,11,12,104,111,102,97,222,217,208,215,179,180,
		189,186,184,191,182,177,213,210,219,220,99,100,109,106,14,9,0,7,15,8,1,6,98,
		101,108,107,212,211,218,221,185,190,183,176,214,209,216,223,187,188,181,178,
		13,10,3,4,96,103,110,105,97,102,111,104,12,11,2,5,186,189,180,179,215,208,
		217,222,100,99,106,109,9,14,7,0,191,184,177,182,210,213,220,219,211,212,221,
		218,190,185,176,183,8,15,6,1,101,98,107,108,10,13,4,3,103,96,105,110,209,
		214,223,216,188,187,178,181,189,186,179,180,208,215,222,217,102,97,104,111,
		11,12,5,2}
	local _crc_table3 = {
		[0]=0,119,238,153,7,112,233,158,14,121,224,151,9,126,231,144,29,106,243,132,
		26,109,244,131,19,100,253,138,20,99,250,141,59,76,213,162,60,75,210,165,53,
		66,219,172,50,69,220,171,38,81,200,191,33,86,207,184,40,95,198,177,47,88,
		193,182,118,1,152,239,113,6,159,232,120,15,150,225,127,8,145,230,107,28,133,
		242,108,27,130,245,101,18,139,252,98,21,140,251,77,58,163,212,74,61,164,211,
		67,52,173,218,68,51,170,221,80,39,190,201,87,32,185,206,94,41,176,199,89,46,
		183,192,237,154,3,116,234,157,4,115,227,148,13,122,228,147,10,125,240,135,
		30,105,247,128,25,110,254,137,16,103,249,142,23,96,214,161,56,79,209,166,63,
		72,216,175,54,65,223,168,49,70,203,188,37,82,204,187,34,85,197,178,43,92,
		194,181,44,91,155,236,117,2,156,235,114,5,149,226,123,12,146,229,124,11,134,
		241,104,31,129,246,111,24,136,255,102,17,143,248,97,22,160,215,78,57,167,
		208,73,62,174,217,64,55,169,222,71,48,189,202,83,36,186,205,84,35,179,196,
		93,42,180,195,90,45}

	--- Calculate the CRC-32 checksum of the string.
	-- @param str [string] the input string to calculate its CRC-32 checksum.
	-- @param init_value [nil/integer] The initial crc32 value. If nil, use 0
	-- @return [integer] The CRC-32 checksum, which is greater or equal to 0,
	-- and less than 2^32 (4294967296).
	local function crc32(str, init_value)
		-- TODO: Check argument
		local crc = (init_value or 0) % 4294967296
		if not _xor8_table then
			GenerateXorTable()
		end
	    -- The value of bytes of crc32
		-- crc0 is the least significant byte
		-- crc3 is the most significant byte
	    local crc0 = crc % 256
	    crc = (crc - crc0) / 256
	    local crc1 = crc % 256
	    crc = (crc - crc1) / 256
	    local crc2 = crc % 256
	    local crc3 = (crc - crc2) / 256

		local _xor_vs_255 = _xor8_table[255]
		crc0 = _xor_vs_255[crc0]
		crc1 = _xor_vs_255[crc1]
		crc2 = _xor_vs_255[crc2]
		crc3 = _xor_vs_255[crc3]
	    for i=1, #str do
			local byte = string_byte(str, i)
			local k = _xor8_table[crc0][byte]
			crc0 = _xor8_table[_crc_table0[k] ][crc1]
			crc1 = _xor8_table[_crc_table1[k] ][crc2]
			crc2 = _xor8_table[_crc_table2[k] ][crc3]
			crc3 = _crc_table3[k]
	    end
		crc0 = _xor_vs_255[crc0]
		crc1 = _xor_vs_255[crc1]
		crc2 = _xor_vs_255[crc2]
		crc3 = _xor_vs_255[crc3]
	    crc = crc0 + crc1*256 + crc2*65536 + crc3*16777216
	    return crc
	end

	Crypto.crc32 = crc32
end
crc32()

function term.duplicate(term1, term2)
	local both = {}
	setmetatable(both, {
		-- the __index override handles table accesses (both[key], both.key, ...)
		-- Make both[key] return term1[key], except if we are accessing a function
		-- In the case of functions, we return a new ad-hoc function that combines term1.key() and term2.key()
		__index = function(_, k)
			if (type(term1[k]) == "function") then
				return function(...)
					-- pcall on term2.k(...) in case it crashes
					-- that way, we can still continue on & call term1.k(...)
					pcall(term2[k], ...)
					-- call term1.k(...) normally and return the value
					return term1[k](...)
					-- side effect: we never get to see term2's return. Who knows!
				end
			else
				-- if we're not accessing a function we just return term1's version of the value
				return term1[k]
			end
		end,
		__call = function(_, f, ...)
			-- function calls get combined in a new function that calls both one-after-another
			-- and returns term1's version of the return value
			pcall(term2[f], ...)
			return term1[f](...)
		end,
		__newindex = function(_, k, v)
			-- affectations and new members get affected to both term1 and term2
			term1[k] = v
			term2[k] = v
		end
	})
	return both
end

---Copy a table's contents
---@param t table
---@param deepcopy boolean
---@return table
function table.clone(t, deepcopy)
	if type(t) ~= "table" then
		error("bad argument #1 to 'clone' (table expected, got" .. type(t) .. ")")
	end

	local r = {}
	for i,v in pairs(t) do
		if deepcopy and type(v) == "table" then
			r[i] = table.clone(v, true)
		else
			r[i] = v
		end
	end

	return r
end

function table.count(t)
    local n = 0
    for _,_ in pairs(t) do
        n = n+1
    end
    return n
end

if turtle ~= nil and turtle.turnTo == nil then
	local old = {}
	turtle.x = 0
	turtle.y = 0
	turtle.z = 0
	turtle.facing = "north"

	if turtle.onEachMove == nil then
		local function onEachMove()
			return true
		end
		turtle.onEachMove = onEachMove
	end

	local function directionToNumber(direction)
		if direction == "north" then
			return 0
		elseif direction == "east" then
			return 1
		elseif direction == "south" then
			return 2
		elseif direction == "west" then
			return 3
		end
	end

	local function turnTo(direction)
		if ( directionToNumber(turtle.facing ) - 1) % 4 == directionToNumber(direction) then
			while turtle.facing ~= direction do
				turtle.turnLeft()
			end
		else
			while turtle.facing ~= direction do
				turtle.turnRight()
			end
		end
		return true
	end
	turtle.turnTo = turnTo

	local function turtGoto(x,y,z)
		local success = true
		local oldDirection = turtle.facing

		while turtle.z < z do --go z+
			success = success and turtle.up() 
			if not success then return false end
		end
		while turtle.z > z do --go z-
			success = success and turtle.down()
			if not success then return false end
		end

		if turtle.x < x then --go x+
			turtle.turnTo("north")
			while turtle.x < x do
				success = success and turtle.forward()
				if not success then return false end
			end
		end
		if turtle.x > x then --go x-
			turtle.turnTo("north")
			while turtle.x > x do
				success = success and turtle.back()
				if not success then return false end
			end
		end

		if turtle.y < y then --go y+
			turtle.turnTo("east")
			while turtle.y < y do
				success = success and turtle.forward()
				if not success then return false end
			end
		end
		if turtle.y > y then --go y-
			turtle.turnTo("east")
			while turtle.y > y do
				success = success and turtle.back()
				if not success then return false end
			end
		end

		turtle.turnTo(oldDirection)
		return success
	end
	turtle["goto"] = turtGoto

	old.turtleUp = turtle.up
	local function up()
		if old.turtleUp() then
			turtle.z = turtle.z+1
			turtle.onEachMove()
			return true
		else
			return false
		end
	end
	turtle.up = up

	old.turtleDown = turtle.down
	local function down()
		if old.turtleDown() then
			turtle.z = turtle.z-1
			turtle.onEachMove()
			return true
		else
			return false
		end
	end
	turtle.down = down

	old.turtleForward = turtle.forward
	local function forward()
		if old.turtleForward() then
			if turtle.facing == "north" then
				turtle.x = turtle.x+1
			elseif turtle.facing == "south" then
				turtle.x = turtle.x-1
			elseif turtle.facing == "east" then
				turtle.y = turtle.y+1
			elseif turtle.facing == "west" then
				turtle.y = turtle.y-1
			end
			turtle.onEachMove()
			return true
		else
			return false
		end
	end
	turtle.forward = forward

	old.turtleBack = turtle.back
	local function back()
		if old.turtleBack() then
			if turtle.facing == "north" then
				turtle.x = turtle.x-1
			elseif turtle.facing == "south" then
				turtle.x = turtle.x+1
			elseif turtle.facing == "east" then
				turtle.y = turtle.y-1
			elseif turtle.facing == "west" then
				turtle.y = turtle.y+1
			end
			turtle.onEachMove()
			return true
		else
			return false
		end
	end
	turtle.back = back

	old.turtleTurnLeft = turtle.turnLeft
	local function turnLeft()
		if old.turtleTurnLeft() then
			if turtle.facing == "north" then
				turtle.facing = "west"
			elseif turtle.facing == "west" then
				turtle.facing = "south"
			elseif turtle.facing == "south" then
				turtle.facing = "east"
			elseif turtle.facing == "east" then
				turtle.facing = "north"
			end
			turtle.onEachMove()
			return true
		else
			return false
		end
	end
	turtle.turnLeft = turnLeft

	old.turtleTurnRight = turtle.turnRight
	local function turnRight()
		if old.turtleTurnRight() then
			if turtle.facing == "north" then
				turtle.facing = "east"
			elseif turtle.facing == "east" then
				turtle.facing = "south"
			elseif turtle.facing == "south" then
				turtle.facing = "west"
			elseif turtle.facing == "west" then
				turtle.facing = "north"
			end
			turtle.onEachMove()
			return true
		else
			return false
		end
	end
	turtle.turnRight = turnRight

	old.getItemSpace = turtle.getItemSpace
	local function getItemSpace(slotNumber)
		if (slotNumber ~= nil) then
			return old.getItemSpace(slotNumber)
		end

		local sum = 0
		for i=1,16 do
			sum = sum + old.getItemSpace(i)
		end
		return sum
	end
	turtle.getItemSpace = getItemSpace

	function turtle.find(item)
		for i=1,16 do
			local v = turtle.getItemDetail(i)
			if v and (item == nil or v.name == item) then
				turtle.select(i)
				return i
			end
		end

		return 0
	end


	function turtle.count(item)
		local sum = 0
		for i=1, 16 do
			local v = turtle.getItemDetail(i)
			if v then
				if (item == nil or v.name == item) then
					sum = sum + v.count
				end
			end
		end
		return sum
	end
end

local sentences = {
	["in front of"] = {
		["front"  ] = "in front of",
		["back"   ] = "at the back of",
		["left"   ] = "left of",
		["right"  ] = "right of",
		["top"    ] = "above",
		["bottom" ] = "below",
		["default"] = "near"
	}
}
function translate(sentence, key)
	if sentences[sentence] then
		return sentences[sentence][key] or sentences[sentence]["default"] or key
	else
		return key
	end
end

local function getDocumentFrom(t)
	if not pretty then 
		pretty = require("cc.pretty") 
		if not pretty then 
			error("cc.pretty not found")
		end
	end
	
	local mt = getmetatable(t)
	if mt ~= nil then
		setmetatable(t, nil)
	end

	local ok, document = pcall(pretty.pretty, t, {
		function_args = settings.get("lua.function_args"),
		function_source = settings.get("lua.function_source"),
	})
	if ok then
		setmetatable(t, mt)
		return document
	else
		setmetatable(t, mt)
		return pretty.text(tostring(t))
	end
end

function tprint(t)
	local document = getDocumentFrom(t)
	pretty.print(document)
end

local function getLines(t, fromLine, toLine, width)
	local width = width or term.getSize()-5
	local document, ok = getDocumentFrom(t)
	local str = pretty.render(document, 1)

	local lines = {}
	local count = 0
	for s in string.gmatch(str, "[^\r\n]+") do
		count = count + 1
		if (count >= fromLine and count <= toLine) then
			table.insert(lines, s)
		end
	end

	return lines, count
end

function tprint_lines(t, fromLine, toLine)
	local lines = getLines(t, fromLine, toLine)

	if #lines == 0 then
		return 0
	end

	local _, y = term.getCursorPos()
	local w, h = term.getSize()
	for i,v in pairs(lines) do
		term.setCursorPos(1, y)
		term.clearLine()
		term.write(v)
		if (y >= h) then
			term.scroll(1)
		else
			y=y+1
		end
	end
	term.setCursorPos(1, y)
	return #lines
end

local function _more(t, pageHeight)
	pageHeight = pageHeight or ({term.current().getSize()})[2]
	local nLinesPrinted
	local nExpectedLinesPrinted
	local iCurrentLine = 1
	local quit = false
	local nextAction = "+page"
	local endOfFile = false
	local debuginfo = ""
	local to
	local from

	while not quit do
		term.clear()
		term.setCursorPos(1, 1)
		if (nextAction == "+page") and not endOfFile then
			from = math.max(1, iCurrentLine)
		elseif (nextAction == "+line") and not endOfFile then
			from = math.max(1, iCurrentLine-pageHeight+2)
		elseif (nextAction == "-line") then
			from = math.max(1, iCurrentLine-pageHeight)
		elseif (nextAction == "-page") then
			from = math.max(1, iCurrentLine-pageHeight*2+2)
		end

		if (from ~= nil) then
			to = from+pageHeight-2
			nExpectedLinesPrinted = to-from+1
			nLinesPrinted = tprint_lines(t, from, to)

			if (nLinesPrinted > 0) then
				iCurrentLine = to+1
			end

			--debuginfo = table.concat({from, to, nExpectedLinesPrinted, nLinesPrinted, pageHeight, tostring(endOfFile)}, ",")
		end

		local _,y = term.getCursorPos()
		
		while true do
			term.clearLine()
			term.setCursorPos(1, pageHeight)
			if (nLinesPrinted >= nExpectedLinesPrinted) or (nextAction == "-line") then
				term.write(":(More)  ")
				endOfFile = false
			else
				term.write("(END)")
				endOfFile = true
			end
			--term.write(" " .. debuginfo)

			local _, key, hold = os.pullEvent("key")
			if key == keys.space or key == keys.pageDown then
				nextAction = "+page"
				if (endOfFile) and (not hold) and false then
					quit = true
					break
				end
				break
			elseif key == keys.pageUp then
				nextAction = "-page"
				break
			elseif key == keys.down then
				nextAction = "+line"
				break
			elseif key == keys.up then
				nextAction = "-line"
				break
			elseif key == keys.q or key == keys.a then
				quit = true
				nextAction = "quit"
				break
			end
		end
		term.setCursorPos(1, pageHeight)
		term.clearLine()
		if not endOfFile then
			term.scroll(1)
			term.setCursorPos(1, y-1)
		end
	end
end

function more(...)
	local args = {...}
	return _more(args, nil)
end

return {Debug, Crypto, Time}