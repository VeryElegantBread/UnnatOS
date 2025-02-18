local split_input = SplitString(Input, " ")
local url = split_input[2]

if url == "" then
	print("url not given")
	return
end

local split_url = SplitString(url, "/")
local path = StringToPath(split_url[#split_url])
if #split_input > 3 then
	path = StringToPath(split_input[3])
end

local text = get_data(url)
if text == nil then
	print("text data not found at " .. url)
	return
end

if new_item(path, false) then
	print("an item already exists at the path " .. PathToString(path))
	return
end

set_text(path, text)
