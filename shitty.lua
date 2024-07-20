-----------------------------------------------------------------------------
function mysplit(inputstr, sep) --https://stackoverflow.com/a/7615129
	local t = {}
	for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
		table.insert(t, str)
	end
	return t
end

------------------------------------------------------------------------------

local isComputerCraft = color and colour and peripheral and peripheral.wrap and redstone and textutils

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
			local last = getfenv()
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
		rem = function(split)
			--adding this here just incase i add erroring for non-existent statements
		end,
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
			getfenv()["_G"][name] = newstr
		end,
		export = function(split)
			local last = getfenv()
			local newSplit = mysplit(split[3],".")
			for i,v in pairs(newSplit) do
				if i ~= #newSplit then
					last = last[v]
				end
			end
			last[newSplit[#newSplit]] = variables[split[2]]
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
			local a = func(table.unpack(args))
			if split[3] then
				variables[split[3]] = a
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
			print(variables[split[2]])
		end,
		forever = function(split)
			while true do
				parse(variables[split[2]])
			end
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
				print(line,response)
			end
		end
	end
	function parse(line)
		local split = mysplit(line:gsub("	",""),"\n")
		for i,v in pairs(split) do
			parseLine(v)
		end
	end
	
	return parse
end

if pcall(debug.getlocal, 4, 1) then
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

