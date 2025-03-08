local split_input = SplitStringOutsideQuotes(Input, " ")
local path = StringToPath(RemoveQuotesIfApplicable(split_input[2]))

if not item_exists(path) then
	print("item not found: " .. PathToString(path))
	return
end

local new_text = string.sub(Input, string.find(Input, " ", string.find(Input, " ") + 1) + 1, string.len(Input))
if new_text:sub(1, 1) == "\"" then
	new_text = RemoveQuotesIfApplicable(split_input[3])
end

new_text = string.gsub(string.gsub(string.gsub(string.gsub(new_text, "\\n", "\n"), "\\\n", "\\n"), "\\\"", "\""), "\\\\", "\\")
if not set_text(path, new_text) then
	print("cannot mutate immutable item")
end
