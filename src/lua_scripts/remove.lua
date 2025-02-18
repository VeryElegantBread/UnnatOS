local path = StringToPath(SplitString(Input, " ")[2])

if item_exists(path) then
	if not remove_item(path) then
		print("cannot remove immutable item")
	end
else
	print("item not found: " .. PathToString(path))
end
