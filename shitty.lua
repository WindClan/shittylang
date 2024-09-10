-----------------------------------------------------------------------------
function mysplit(inputstr, sep) --https://stackoverflow.com/a/7615129
	local t = {}
	for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
		table.insert(t, str)
	end
	return t
end

------------------------------------------------------------------------------

local isComputerCraft = colors and colours and peripheral and peripheral.wrap and redstone and textutils
local printErrorFunc = isComputerCraft and printError or print
local function open(fileName,mode)
	if isComputerCraft then
		return fs.open(fileName,mode)
	else
		return io.open(fileName,mode)
	end
end
local function readall(handle)
	if isComputerCraft then
		return handle.readAll()
	else
		return handle:read("*a")
	end
end
local function close(handle)
	if isComputerCraft then
		return handle.close()
	else
		return handle:close()
	end
end

if not getfenv then
	function getfenv(level) 
		return _ENV
	end
end

local function newParser()
	local queue = {}
	local variables = {}
	local args = {}
	local currentInst = nil
	local inForeverLoop = false
	local currentFunc = ""
	local currentSubFunc = ""
	local parse = nil
	local function addToQueue(block)
		local split = mysplit(block:gsub("	",""),"\n")
		for i=1,#split do
			local v = split[#split+1-i]
			table.insert(queue,1,v)
		end
	end
	local function parseVariables(split,origin)
		local arg1 = split[1]:lower()
		local newstr
		if arg1 == "string" or arg1 == "str" then
			if not origin or string.gsub(origin,".[setvaraddarglob]- .- [string]- ","") == nil then
				newstr = split[2]
				for i,v in pairs(split) do
					if i > 2 then
						if v == nil then
							v = ""
						end
						newstr = newstr.." "..v
					end
				end
			else
				newstr = string.gsub(origin,"[setvaraddarglob]- .- [string]- ","")
			end
		elseif arg1 == "space" then
			newstr = " "
		elseif arg1 == "number" or arg1 == "num" then
			newstr = tonumber(split[2])
		elseif arg1 == "obj" or arg1 == "object" then
			local last = getfenv(0)
			for i,v in pairs(mysplit(split[2],".")) do
				last = last[v]
			end
			newstr = last
		elseif arg1 == "varobj" then
			local last = variables
			for i,v in pairs(mysplit(split[2],".")) do
				last = last[v]
			end
			newstr = last
		elseif arg1 == "var" or arg1 == "variable" then
			newstr = variables[split[2]]
		elseif arg1 == "func" or arg1 == "function" then
			newstr = function() parse(variables[split[2]]) end
		elseif arg1 == "true" then
			newstr = true
		elseif arg1 == "false" then
			newstr = false
		elseif arg1 == "nil" or arg1 == "none" or arg1 == "null" then
			newstr = nil --i could ignore this but it feels wrong
		elseif arg1 == "table" or arg1 == "tab" then
			newstr = {}
		else
			error("Unknown variable type!")
		end
		return newstr
	end

	local commands = {
		setvar = function(origin,split)
			local name = split[2]
			table.remove(split,1)
			table.remove(split,1)
			local newstr = parseVariables(split,origin)
			variables[name] = newstr
		end,
		rem = function(origin,split) end,
		addarg = function(origin,split)
			table.remove(split,1)
			local newstr = parseVariables(split,origin)
			table.insert(args,newstr)
		end,
		setglobal = function(origin,split)
			local name = split[2]
			table.remove(split,1)
			table.remove(split,1)
			local newstr = parseVariables(split,origin)
			getfenv(0)["_G"][name] = newstr
		end,
		export = function(origin,split)
			local last = getfenv(0)
			local newSplit = mysplit(split[3],".")
			for i,v in pairs(newSplit) do
				if i ~= #newSplit then
					last = last[v]
				end
			end
			last[newSplit[#newSplit]] = variables[split[2]]
		end,
		error = function(origin,split)
			local last = getfenv(0)
			table.remove(split,1)
			local str = split[1]
			table.remove(split,1)
			for i,v in pairs(split) do
				str = str.." "..v
			end
			error(str,0)
		end,
		expvar = function(origin,split)
			local last = variables
			local newSplit = mysplit(split[3],".")
			for i,v in pairs(newSplit) do
				if i ~= #newSplit then
					last = last[v]
				end
			end
			last[newSplit[#newSplit]] = variables[split[2]]
		end,
		startfunc = function(origin,split)
			currentFunc = split[2]
			variables[currentFunc] = ""
		end,
		startsubfunc = function(origin,split)
			currentSubFunc = split[2]
			variables[currentSubFunc] = ""
		end,
		exec = function(origin,split)
			addToQueue(variables[split[2]])
		end,
		runlua = function(origin,split)
			local func = variables[split[2]]
			local a = table.pack(func(table.unpack(args)))
			table.remove(split,1)
			table.remove(split,1)
			for i,v in pairs(a) do
				if split[i] then
					variables[split[i]] = v
				end
			end
			args = {}
		end,
		add = function(origin,split)
			table.remove(split,1)
			local last = variables[split[1]]
			table.remove(split,1)
			for i,v in pairs(split) do
				if i ~= #split then
					last = last + variables[v]
				end
			end
			variables[split[#split]] = last
		end,
		subtract = function(origin,split)
			table.remove(split,1)
			local last = variables[split[1]]
			table.remove(split,1)
			for i,v in pairs(split) do
				if i ~= #split then
					last = last - variables[v]
				end
			end
			variables[split[#split]] = last
		end,
		divide = function(origin,split)
			table.remove(split,1)
			local last = variables[split[1]]
			table.remove(split,1)
			for i,v in pairs(split) do
				if i ~= #split then
					last = last / variables[v]
				end
			end
			variables[split[#split]] = last
		end,
		multiply = function(origin,split)
			table.remove(split,1)
			local last = variables[split[1]]
			table.remove(split,1)
			for i,v in pairs(split) do
				if i ~= #split then
					last = last * variables[v]
				end
			end
			variables[split[#split]] = last
		end,
		addstr = function(origin,split)
			table.remove(split,1)
			local last = ""
			for i,v in pairs(split) do
				if i ~= #split then
					last = last .. variables[v]
				end
			end
			variables[split[#split]] = last
		end, 
		out = function(origin,split)
			table.remove(split,1)
			local varTable = {}
			for i,v in pairs(split) do
				varTable[i] = variables[v]
			end
			print(table.unpack(varTable))
		end,
		forever = function(origin,split)
			inForeverLoop = true
			while inForeverLoop do
				parse(variables[split[2]])
			end
		end,
		input = function(origin,split)
			variables[split[2]] = io.read()
		end,
		repeatuntil = function(origin,split)
			while variables[split[3]] ~= variables[split[4]] do
				parse(variables[split[2]])
			end
		end,
		["break"] = function(origin,split)
			inForeverLoop = false
		end,
		sleep = function(origin,split)
			sleep(tonumber(split[2]))
		end,
		greater = function(origin,split)
			if variables[split[2]] > variables[split[3]] then
				parse(variables[split[4]])
			elseif split[5] then
				parse(variables[split[5]])
			end
		end,
		lesser = function(origin,split)
			if variables[split[2]] < variables[split[3]] then
				parse(variables[split[4]])
			elseif split[5] then
				parse(variables[split[5]])
			end
		end,
		greaterequal = function(origin,split)
			if variables[split[2]] >= variables[split[3]] then
				parse(variables[split[4]])
			elseif split[5] then
				parse(variables[split[5]])
			end
		end,
		lesserequal = function(origin,split)
			if variables[split[2]] <= variables[split[3]] then
				parse(variables[split[4]])
			elseif split[5] then
				parse(variables[split[5]])
			end
		end,
		equal = function(origin,split)
			if variables[split[2]] == variables[split[3]] then
				parse(variables[split[4]])
			elseif split[5] then
				parse(variables[split[5]])
			end
		end,
		exists = function(origin,split)
			if variables[split[2]] ~= nil then
				parse(variables[split[3]])
			elseif split[4] then
				parse(variables[split[4]])
			end
		end,
		["and"] = function(origin,split)
			if variables[split[2]] and variables[split[3]] then
				parse(variables[split[4]])
			elseif split[5] then
				parse(variables[split[5]])
			end
		end,
		["or"] = function(origin,split)
			if variables[split[2]] or variables[split[3]] then
				parse(variables[split[4]])
			elseif split[5] then
				parse(variables[split[5]])
			end
		end,
		[""] = function(origin,split) end,
		[" "] = function(origin,split) end
	}

	local function parseLine(line)
		local split = mysplit(line," ")
		local command = split[1]:lower()
		if not command then
			return
		end
		if command == "endfunc" and currentFunc then
			currentFunc = ""
		elseif currentFunc ~= "" then
			variables[currentFunc] = variables[currentFunc].."\n"..line
		elseif command == "endsubfunc" and currentSubFunc then
			currentSubFunc = ""
		elseif currentSubFunc ~= "" then
			variables[currentSubFunc] = variables[currentSubFunc].."\n"..line
		elseif commands[command] then
			local success, response = pcall(commands[command],line,split)
			if not success then
				printErrorFunc(response)
				return false, line
			end
		elseif command:sub(1,2) ~= "#!" then
			printErrorFunc("No such command \""..command.."\"")
			return false, line
		end
		return true
	end
	function parse(line)
		addToQueue(line:gsub("	",""))
		local i = 1
		while true do
			if #queue <= 0 then
				break
			end
			local v = queue[1]
			table.remove(queue,1)
			local success,line = parseLine(v)
			if not success then
				error("Error executing "..i..": "..line)
				break
			end
			i = i + 1
		end
	end
	
	return parse
end
local args = {...}
if pcall(debug.getlocal, 4, 1) then --check from https://stackoverflow.com/a/49376823 (modified)
	return newParser
else
	local path = ""
	for i,v in pairs(args) do
		if i ~= 1 then
			path = path.." "
		end
		path = path..v
	end
	local file = open(path,"r")
	local dat = readall(file)
	close(file)
	newParser()(dat)
end
