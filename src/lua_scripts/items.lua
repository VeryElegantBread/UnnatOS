local path = StringToPath(RemoveQuotesIfApplicable(SplitStringOutsideQuotes(Input, " ")[2]))

if item_exists(path) then
	local return_table = { "Mutable  Executable  Name" }
	for _, name in pairs(get_children(path)) do
		local item_string
		local item_path = {}
		for _, v in pairs(path) do
			table.insert(item_path, v)
		end
		table.insert(item_path, name)

		if is_mutable(item_path) then
			item_string = "true     "
		else
			item_string = "false    "
		end
		if is_executable(item_path) then
			item_string = item_string .. "true        "
		else
			item_string = item_string .. "false       "
		end

		item_string = item_string .. name

		table.insert(return_table, item_string)
	end
	return return_table
else
	print("item not found: " .. PathToString(path))
end
