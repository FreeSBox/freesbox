---Allows us to directly download files from github.

---Downloads file from our repo, or gets it from cache.
---@param filename string
---@param callback fun(path: string)
function FSB.DownloadFile(filename, callback)
	local path = "freesbox/" .. filename
	if file.Exists(path, "DATA") then
		callback(path)
		return
	end

	http.Fetch("https://raw.githubusercontent.com/FreeSBox/streamed-files/master/" .. filename, function(body, size, headers, code)
		if not file.IsDir("freesbox", "DATA") then
			file.CreateDir("freesbox")
		end
		file.Write(path, body)
		callback(path)
	end)
end
