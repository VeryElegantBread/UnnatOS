local path = StringToPath(RemoveQuotesIfApplicable(SplitStringOutsideQuotes(Input, " ")[2]))

if path == {} then
	print("no path found")
	return
end

local parent_path = {}
for i = 1, #path - 1 do
	table.insert(parent_path, path[i])
end

for char in string.gmatch(path[#path], ".") do
	if char == "~" then
		print("item name cannot contain \"~\"")
		return
	end
end

if parent_path[1] == "System" and parent_path[2] == "Backups" then
	print("Items in the backups item get deleted when the OS restarts.")
	return
end

if item_exists(parent_path) then
	local already_existed = new_item(path, false)
	if already_existed then
		print("an item at that path already exists")
	end
else
	print("the parent item doesn't exist")
end
