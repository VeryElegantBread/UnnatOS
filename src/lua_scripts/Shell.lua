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

function EvaluateCommand(command)
	local item_path = command:sub(1, command:find(" ") - 1)

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
	elseif item_exists({ "System", programs_item, item_path }) then
		if is_executable({ "System", programs_item, item_path }) then
			local returned_data = require("System/" .. programs_item .. "/" .. item_path)
			package.loaded["System/" .. programs_item .. "/" .. item_path] = nil
			if type(returned_data) == "table" then
				return returned_data
			end
			return {}
		else
			print("item not executable: System/" .. programs_item .. "/" .. item_path)
			return {}
		end
	elseif item_exists(StringToPath(item_path)) then
		if is_executable(StringToPath(item_path)) then
			local path_as_string = PathToString(StringToPath(item_path))
			local returned_data = require(path_as_string)
			package.loaded[path_as_string] = nil
			if type(returned_data) == "table" then
				return returned_data
			end
		else
			print("item not executable: " .. PathToString(StringToPath(item_path)))
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
	for _, section in pairs(SplitString(base_input, " -> ")) do
		Input = string.sub(section, 1, string.len(section) - 1) .. table.concat(result, "\n")
		result = EvaluateCommand(Input)
	end
	for _, i in pairs(result) do
		print(i)
	end
end
