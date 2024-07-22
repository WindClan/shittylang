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

local function newParser()
	local variables = {}
	local args = {}
	local currentInst = nil
	local inForeverLoop = false
	local currentFunc = ""
	local currentSubFunc = ""
	local parse = nil
	
	local function parseVariables(split)
		local arg1 = split[1]:lower()
		local newstr
		if arg1 == "string" or arg1 == "str" then
			newstr = split[2]
			for i,v in pairs(split) do
				if i > 2 then
					if v == nil then
						v = ""
					end
					newstr = newstr.." "..v
				end
			end
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
		end
		return newstr
	end

	local commands = {
		setvar = function(split)
			local name = split[2]
			table.remove(split,1)
			table.remove(split,1)
			local newstr = parseVariables(split)
			variables[name] = newstr
		end,
		rem = function(split) end,
		addarg = function(split)
			table.remove(split,1)
			local newstr = parseVariables(split)
			table.insert(args,newstr)
		end,
		setglobal = function(split)
			local name = split[2]
			table.remove(split,1)
			table.remove(split,1)
			local newstr = parseVariables(split)
			getfenv(0)["_G"][name] = newstr
		end,
		export = function(split)
			local last = getfenv(0)
			local newSplit = mysplit(split[3],".")
			for i,v in pairs(newSplit) do
				if i ~= #newSplit then
					last = last[v]
				end
			end
			last[newSplit[#newSplit]] = variables[split[2]]
		end,
		error = function(split)
			local last = getfenv(0)
			table.remove(split,1)
			local str = split[1]
			table.remove(split,1)
			for i,v in pairs(split) do
				str = str.." "..v
			end
			error(str,0)
		end,
		expvar = function(split)
			local last = variables
			local newSplit = mysplit(split[3],".")
			for i,v in pairs(newSplit) do
				if i ~= #newSplit then
					last = last[v]
				end
			end
			last[newSplit[#newSplit]] = variables[split[2]]
		end,
		startfunc = function(split)
			currentFunc = split[2]
			variables[currentFunc] = ""
		end,
		startsubfunc = function(split)
			currentSubFunc = split[2]
			variables[currentSubFunc] = ""
		end,
		exec = function(split)
			parse(variables[split[2]])
		end,
		runlua = function(split)
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
		add = function(split)
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
		subtract = function(split)
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
		divide = function(split)
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
		multiply = function(split)
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
		addstr = function(split)
			table.remove(split,1)
			local last = ""
			for i,v in pairs(split) do
				if i ~= #split then
					last = last .. variables[v]
				end
			end
			variables[split[#split]] = last
		end, 
		out = function(split)
			table.remove(split,1)
			local varTable = {}
			for i,v in pairs(split) do
				varTable[i] = variables[v]
			end
			print(table.unpack(varTable))
		end,
		forever = function(split)
			inForeverLoop = true
			while inForeverLoop do
				parse(variables[split[2]])
			end
		end,
		input = function(split)
			variables[split[2]] = io.read()
		end,
		repeatUntil = function(split) end
			while variables[split[3]] ~= variables[split[4]] do
				parse(variables[split[2]])
			end
		end,
		break = function(split)
			inForeverLoop = false
		end,
		sleep = function(split)
			sleep(tonumber(split[2]))
		end,
		greater = function(split)
			if variables[split[2]] > variables[split[3]] then
				parse(variables[split[4]])
			elseif split[5] then
				parse(variables[split[5]])
			end
		end,
		lesser = function(split)
			if variables[split[2]] < variables[split[3]] then
				parse(variables[split[4]])
			elseif split[5] then
				parse(variables[split[5]])
			end
		end,
		greaterequal = function(split)
			if variables[split[2]] >= variables[split[3]] then
				parse(variables[split[4]])
			elseif split[5] then
				parse(variables[split[5]])
			end
		end,
		lesserequal = function(split)
			if variables[split[2]] <= variables[split[3]] then
				parse(variables[split[4]])
			elseif split[5] then
				parse(variables[split[5]])
			end
		end,
		equal = function(split)
			if variables[split[2]] == variables[split[3]] then
				parse(variables[split[4]])
			elseif split[5] then
				parse(variables[split[5]])
			end
		end,
		exists = function(split)
			if variables[split[2]] ~= nil then
				parse(variables[split[3]])
			elseif split[4] then
				parse(variables[split[4]])
			end
		end,
		["and"] = function(split)
			if variables[split[2]] and variables[split[3]] then
				parse(variables[split[4]])
			elseif split[5] then
				parse(variables[split[5]])
			end
		end,
		["or"] = function(split)
			if variables[split[2]] or variables[split[3]] then
				parse(variables[split[4]])
			elseif split[5] then
				parse(variables[split[5]])
			end
		end,
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
			local success, response = pcall(commands[command],split)
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
		local split = mysplit(line:gsub("	",""),"\n")
		for i,v in pairs(split) do
			local success,line = parseLine(v)
			if not success then
				error("Error at line "..i..": "..line)
				break
			end
		end
	end
	
	return parse
end

if pcall(debug.getlocal, 4, 1) then --check from https://stackoverflow.com/a/49376823
	return newParser
else
	local args = {...}
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

