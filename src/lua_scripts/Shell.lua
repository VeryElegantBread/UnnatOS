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

if item_exists({ "System", "Startup.lua" }) and not SafeMode then
	require("System/Startup.lua")
end
print(get_text({ "System" }))

local programs_item
if SafeMode then
	programs_item = "Backups"
else
	programs_item = "Programs"
end

while true do
	io.write("$ ")
	local base_input = io.read()
	Input = string.sub(base_input, 1, string.len(base_input)) .. " "

	local item_path = string.sub(Input, 1, string.find(Input, " ") - 1)

	if string.gsub(Input, "%s", "") == "" then
		-- do nothing
	elseif item_path == "move" then
		local new_item = StringToPath(SplitString(Input, " ")[2])
		if item_exists(new_item) then
			CurrentItem = new_item
		else
			print("item not found: " .. PathToString(new_item))
		end
	elseif item_path == "pci" then
		print(PathToString(CurrentItem))
	elseif item_path == "help" then
		print("Base Commands:")
		print("help: Print this")
		print("move: Move into another item (cd)")
		print("pci: Print current item (pwd)")
		print("read: Print text inside item (cat)")
		print("items: Print names of items in an item, along with if they are immutable and if they are executable (ls)")
		print("new: Make a new item (touch)")
		print("write: Write text to an item (>)")
		print("se: Give true or false to set an item as executable or not executable (chmod +x)")
		print("remove: Remove an item (rm)")
		print("save: Save the file system")
		print("exit: Save the file system and exit the operating system (shutdown)")
		print("You can also put the path to an executable item to run that")
	elseif item_exists({ "System", programs_item, item_path }) then
		if is_executable({ "System", programs_item, item_path }) then
			local returned_data = require("System/" .. programs_item .. "/" .. item_path)
			if type(returned_data) == "table" then
				for _, v in pairs(returned_data) do
					print(v)
				end
			end
			package.loaded["System/" .. programs_item .. "/" .. item_path] = nil
		else
			print("item not executable: System/" .. programs_item .. "/" .. item_path)
		end
	elseif item_exists(StringToPath(item_path)) then
		if is_executable(StringToPath(item_path)) then
			local path_as_string = PathToString(StringToPath(item_path))
			local returned_data = require(path_as_string)
			if type(returned_data) == "table" then
				for _, v in pairs(returned_data) do
					print(v)
				end
			end
			package.loaded[path_as_string] = nil
		else
			print("item not executable: " .. PathToString(StringToPath(item_path)))
		end
	elseif Input ~= nil then
		print("item not found: " .. PathToString(StringToPath(item_path)) .. "")
	end
end
