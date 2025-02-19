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

local past_commands = {}

while true do
	local base_input = ""
	local current_string = ""
	local cursor_pos = 0
	local command_num = 0
	while true do
		cursor_pos = math.min(cursor_pos, string.len(current_string))
		io.write("\27[2K")
		io.write("\27[0G")
		io.write("$ " .. current_string)
		io.write("\27[" .. cursor_pos + 3 .. "G")
		io.flush()
		local key = get_key_press()
		if key[1] == "c" and key[2] == "Ctrl" then
			exit_os()
		elseif key[2] == "Left" then
			cursor_pos = math.max(cursor_pos - 1, 0)
		elseif key[2] == "Right" then
			cursor_pos = cursor_pos + 1
		elseif key[2] == "Up" then
			command_num = math.min(command_num + 1, #past_commands)
			if command_num == 0 then
				current_string = base_input
			else
				current_string = past_commands[#past_commands - command_num + 1]
			end
		elseif key[2] == "Down" then
			command_num = math.max(command_num - 1, 0)
			if command_num == 0 then
				current_string = base_input
			else
				current_string = past_commands[#past_commands - command_num + 1]
			end
		elseif key[1] == "\n" then
			if string.gsub(current_string, "%s", "") ~= "" then
				table.insert(past_commands, current_string)
			end
			base_input = current_string
			io.write("\n")
			break
		elseif key[2] == "Backspace" then
			if command_num > 0 then
				base_input = past_commands[#past_commands - command_num + 1]
				command_num = 0
			end
			if cursor_pos > 0 then
				base_input = string.sub(base_input, 1, cursor_pos - 1) .. string.sub(base_input, cursor_pos + 1)
				cursor_pos = cursor_pos - 1
			end
			current_string = base_input
		elseif key[1] then
			if command_num > 0 then
				base_input = past_commands[#past_commands - command_num + 1]
				command_num = 0
			end
			base_input = string.sub(base_input, 1, cursor_pos) .. key[1] .. string.sub(base_input, cursor_pos + 1)
			cursor_pos = cursor_pos + 1
			current_string = base_input
		end
	end
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
		print("download: get a file from the internet (curl)")
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
