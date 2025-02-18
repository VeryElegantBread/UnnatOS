local path = StringToPath(SplitString(Input, " ")[2])

if item_exists(path) then
	return { get_text(path) }
else
	print("item not found: " .. PathToString(path))
end
