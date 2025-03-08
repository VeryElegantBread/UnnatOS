function SplitString(input_string, separator)
	local return_table = {}

	for string in string.gmatch(input_string .. separator, "(.-)" .. separator) do
		table.insert(return_table, string)
	end

	if #return_table == 1 and return_table[1] == "" then
		return {}
	end
	return return_table
end

function SplitStringOutsideQuotes(input_string, seperator)
	input_string = input_string .. seperator
	local return_table = {}

	local segment_start = 1
	local escaped = false
	local quotations = false
	for i = 1, #input_string - #seperator + 1, 1 do
		local char = input_string:sub(i, i)
		if char == "\\" then
			escaped = not escaped
		else
			if char == "\"" and input_string:sub(i - 1, i - 1) == " " and not quotations and not escaped then
				quotations = true
			elseif char == "\"" and input_string:sub(i + 1, i + 1) == " " and quotations and not escaped then
				quotations = false
			elseif input_string:sub(i, i + #seperator - 1) == seperator and not quotations then
				local segment = string.sub(input_string, segment_start, i - 1)
				if segment then
					table.insert(return_table, segment)
				else
					table.insert(return_table, "")
				end
				segment_start = i + #seperator
			end
			escaped = false
		end
	end

	if quotations then
		print("No end quotes found.")
	end
	return return_table
end


function RemoveQuotesIfApplicable(input_string)
	if input_string:sub(1, 1) == "\"" and input_string:sub(input_string:len(), input_string:len()) == "\"" then
		return input_string:sub(2, input_string:len() - 1)
	end
	return input_string
end

function StringToPath(input_string)
	local path_table
	if string.sub(input_string, 1, 1) == "~" then
		path_table = SplitString(string.sub(input_string, 3, string.len(input_string)), "/")
	else
		path_table = {}
		for _, v in pairs(CurrentItem) do
			table.insert(path_table, v)
		end
		for _, v in pairs(SplitString(input_string, "/")) do
			table.insert(path_table, v)
		end
	end

	local item_num = 1
	while item_num <= #path_table do
		if path_table[item_num] == ".." then
			table.remove(path_table, item_num)
			table.remove(path_table, item_num - 1)
			item_num = item_num - 1
		elseif path_table[item_num] == "." or path_table[item_num] == "" then
			table.remove(path_table, item_num)
		else
			item_num = item_num + 1
		end
	end

	return path_table
end

function PathToString(input_path)
	local path_string = ""
	for _, name in pairs(input_path) do
		path_string = path_string .. "/" .. name
	end

	return string.sub(path_string, 2, string.len(path_string))
end

CurrentItem = {}
local programs_item

function GetCommandItem(command)
	if item_exists({ "System", programs_item, command }) then
		return { "System", programs_item, command }
	elseif item_exists(StringToPath(command)) then
		return StringToPath(command)
	end
end

function EvaluateCommand(command)
	local item_path = command:sub(1, command:find(" ") - 1)

	local command_item = GetCommandItem(item_path)
	if command:gsub("%s", "") == "" then
		return {}
	elseif item_path == "move" then
		local new_item = StringToPath(SplitString(command, " ")[2])
		if item_exists(new_item) then
			CurrentItem = new_item
		else
			print("item not found: " .. PathToString(new_item))
		end
		return {}
	elseif item_path == "pci" then
		return PathToString(CurrentItem)
	elseif item_path == "help" then
		return {
			"Base Commands:",
			"help: Print this",
			"move: Move into another item (cd)",
			"pci: Print current item (pwd)",
			"read: Print text inside item (cat)",
			"items: Print names of items in an item, along with if they are immutable and if they are executable (ls)",
			"new: Make a new item (touch)",
			"write: Write text to an item (>)",
			"se: Give true or false to set an item as executable or not executable (chmod +x)",
			"remove: Remove an item (rm)",
			"download: get a file from the internet (curl)",
			"save: Save the file system",
			"exit: Save the file system and exit the operating system (shutdown)",
			"You can also put the path to an executable item to run that",
			"Pipe with \" -> \"",
		}
	elseif command_item then
		if is_executable(command_item) then
			local returned_data = require(PathToString(command_item))
			package.loaded[PathToString(command_item)] = nil
			if type(returned_data) == "table" then
				return returned_data
			end
			return {}
		else
			print("item not executable: " .. PathToString(command_item))
			return {}
		end
	elseif command ~= nil then
		print("item not found: " .. PathToString(StringToPath(item_path)) .. "")
		return {}
	end
end

Prompt = "$ "

if item_exists({ "System", "Startup.lua" }) and not SafeMode then
	require("System/Startup.lua")
end
print(get_text({ "System" }))

if SafeMode then
	programs_item = "Backups"
else
	programs_item = "Programs"
end

while true do
	io.write(Prompt)
	local base_input = io.read()
	local result = {}
	for _, section in pairs(SplitStringOutsideQuotes(base_input, " -> ")) do
		Input = string.sub(section, 1, string.len(section)) .. " " .. table.concat(result, "\n")
		result = EvaluateCommand(Input)
	end
	for _, i in pairs(result) do
		print(i)
	end
end
