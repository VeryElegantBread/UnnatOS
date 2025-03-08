local split_input = SplitStringOutsideQuotes(Input, " ")
local path = StringToPath(RemoveQuotesIfApplicable(split_input[2]))

local new_executability = true
if #SplitString(Input, " ") >= 3 and RemoveQuotesIfApplicable(split_input[3]) == "false" then
	new_executability = false
end

if item_exists(path) then
	if not set_executable(path, new_executability) then
		print("cannot change the executability status of immutable item")
	end
else
	print("item not found: " .. PathToString(path))
end
