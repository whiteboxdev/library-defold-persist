--------------------------------------------------------------------------------
-- License
--------------------------------------------------------------------------------

-- Copyright (c) 2024 White Box Dev

-- This software is provided 'as-is', without any express or implied warranty.
-- In no event will the authors be held liable for any damages arising from the use of this software.

-- Permission is granted to anyone to use this software for any purpose,
-- including commercial applications, and to alter it and redistribute it freely,
-- subject to the following restrictions:

-- 1. The origin of this software must not be misrepresented; you must not claim that you wrote the original software.
--    If you use this software in a product, an acknowledgment in the product documentation would be appreciated but is not required.

-- 2. Altered source versions must be plainly marked as such, and must not be misrepresented as being the original software.

-- 3. This notice may not be removed or altered from any source distribution.

--------------------------------------------------------------------------------
-- Information
--------------------------------------------------------------------------------

-- GitHub: https://github.com/whiteboxdev/library-defold-persist

--------------------------------------------------------------------------------
-- Variables
--------------------------------------------------------------------------------

local persist = {}

-- Maps file names to file paths to avoid redundantly constructing the same paths over and over.
-- { <file_name> = <file_path>, ... }
local file_paths = {}

-- Maps file names to unsaved data fields.
-- Upon saving a file, each unsaved field will replace its corresponding saved field.
-- { <file_name> = { <key> = <value>, ... }, ... }
local unsaved_data = {}

--------------------------------------------------------------------------------
-- Local Functions
--------------------------------------------------------------------------------

-- Caches the absolute path of a file.
local function cache_file_path(file_name)
	local project_title = sys.get_config_string("project.title")
	local system_info = sys.get_sys_info()
	if system_info.system_name == "Linux" then
		-- Linux uses the $XDG_CONFIG_HOME environment variable as the file path prefix.
		-- If this variable is not set, then we default to the conventional "~/.config/" prefix.
		local xdg_config_home = os.getenv("XDG_CONFIG_HOME")
		if xdg_config_home then
			file_paths[file_name] = string.format("%s/%s/%s", xdg_config_home, project_title, file_name)
		else
			file_paths[file_name] = sys.get_save_file("config/" .. project_title, file_name)
		end
	else
		file_paths[file_name] = sys.get_save_file(project_title, file_name)
	end
end

-- Checks if a file has the ".json" extension.
local function is_json_file(file_name)
	return string.sub(file_paths[file_name], -5) == ".json"
end

-- Saves data that was written to a file.
local function save(file_name, data)
	-- If this is a JSON file, then save it using Lua's `io` API.
	if is_json_file(file_name) then
		local file_handle = io.open(file_paths[file_name], "w")
		if file_handle then
			local file_text = json.encode(data)
			file_handle:write(file_text)
			file_handle:close()
		else
			print("Defold Persist: save() -> Failed to open file: " .. file_paths[file_name])
		end
	-- If this is a non-JSON file, then save it using Defold's `sys` API.
	else
		if sys.save(file_paths[file_name], data) then
			unsaved_data[file_name] = nil
		else
			print("Defold Persist: save() -> Failed to save file: " .. file_paths[file_name])
		end
	end
end

--------------------------------------------------------------------------------
-- Module Functions
--------------------------------------------------------------------------------

-- Creates a file with the specified data.
-- If the file already exists, then its data can be overwritten.
function persist.create(file_name, data, overwrite)
	if not persist.exists(file_name) or overwrite then
		unsaved_data[file_name] = data
		save(file_name, data)
	end
end

-- Writes data to a file.
function persist.write(file_name, key, value)
	if not persist.exists(file_name) then
		print("Defold Persist: persist.write() -> File does not exist: " .. file_paths[file_name])
		return
	end
	if not unsaved_data[file_name] then
		unsaved_data[file_name] = {}
	end
	unsaved_data[file_name][key] = value
end

-- Flushes unsaved data from a file.
-- If a key is specified, then only that field is flushed.
function persist.flush(file_name, key)
	if not persist.exists(file_name) then
		print("Defold Persist: persist.flush() -> File does not exist: " .. file_paths[file_name])
		return
	end
	if unsaved_data[file_name] then
		if key then
			unsaved_data[file_name][key] = nil
		else
			unsaved_data[file_name] = nil
		end
	end
end

-- Saves data that was written to a file.
function persist.save(file_name)
	if not persist.exists(file_name) then
		print("Defold Persist: persist.save() -> File does not exist: " .. file_paths[file_name])
		return
	end
	local data = persist.load(file_name)
	save(file_name, data)
end

-- Loads data from a file, including written data.
function persist.load(file_name)
	if not persist.exists(file_name) then
		print("Defold Persist: persist.load() -> File does not exist: " .. file_paths[file_name])
		return
	end
	local saved_data
	-- If this is a JSON file, then load it using Lua's `io` API.
	if is_json_file(file_name) then
		local file_handle = io.open(file_paths[file_name], "r")
		if file_handle then
			local file_text = file_handle:read("*all")
			file_handle:close()
			saved_data = json.decode(file_text)
		else
			print("Defold Persist: persist.load() -> Failed to open file: " .. file_paths[file_name])
		end
	-- If this is a non-JSON file, then load it using Defold's `sys` API.
	else
		saved_data = sys.load(file_paths[file_name]) or {}
	end
	-- Overwrite loaded data with any written data.
	local unsaved_data = unsaved_data[file_name] or {}
	for key, value in pairs(unsaved_data) do
		saved_data[key] = value
	end
	return saved_data
end

-- Checks if a file exists.
function persist.exists(file_name)
	if file_paths[file_name] then
		return sys.exists(file_paths[file_name])
	end
	cache_file_path(file_name)
	return sys.exists(file_paths[file_name])
end

return persist