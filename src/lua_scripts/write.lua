local split_input = SplitString(Input, " ")
local path = StringToPath(split_input[2])

if not item_exists(path) then
	print("item not found: " .. PathToString(path))
	return
end

local input_after_path = string.sub(Input, string.find(Input, " ", string.find(Input, " ") + 1) + 1, string.len(Input))

local new_text = input_after_path
if string.sub(input_after_path, 1, 1) == "\"" then
	local escaped = true
	local char_num = 1
	for char in string.gmatch(input_after_path, ".") do
		if char == "\\" then
			escaped = not escaped
		elseif char == "\"" and not escaped then
			new_text = string.sub(input_after_path, 2, char_num)
		else
			escaped = false
		end
		char_num = char_num + 1
	end
end

new_text = string.gsub(string.gsub(new_text, "\\n", "\n"), "\\\n", "\\n")
if not set_text(path, new_text) then
	print("cannot mutate immutable item")
end
