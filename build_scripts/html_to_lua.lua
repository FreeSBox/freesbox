--[[
This script will automatically convert html files to lua files with the html contents.
It will also remove all lines that contain `<!-- not_in_lua -->`

Run this file from the freesbox directory, not from the build_scripts directory.
Unix only, Windows will not work, because lua sucks and can't iterate files.
]]

for file_path in io.popen([[find -type f -iname "*.html"]]):lines() do
	local input_file = io.open(file_path, "rb")
	local output_file = io.open(file_path .. ".lua", "wb")
	assert(output_file)
	assert(input_file)

	local output_buffer = ""

	for line in input_file:lines("*L") do
		if string.find(line, "<!-- not_in_lua -->", 1, true) == nil then
			output_buffer = output_buffer .. line
		end
	end

	output_file:write("return [[\n" .. output_buffer .. "\n]]")

	input_file:close()
	output_file:close()

	print("Generated", file_path .. ".lua")
end

