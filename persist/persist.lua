--------------------------------------------------------------------------------
-- License
--------------------------------------------------------------------------------

-- Copyright (c) 2024 Klayton Kowalski

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

-- GitHub: https://github.com/klaytonkowalski/library-defold-persist

--------------------------------------------------------------------------------
-- Variables
--------------------------------------------------------------------------------

local persist = {}

local unsaved_data = {}

--------------------------------------------------------------------------------
-- Local Functions
--------------------------------------------------------------------------------

-- Gets the absolute path of a file in the OS's standard location for save files.
-- Does not check if the file actually exists.
-- Returns a string.
local function get_file_path(file_name)
	local application_title = sys.get_config_string("project.title")
	return sys.get_save_file(application_title, file_name)
end

-- Checks if a file exists.
-- Returns true or false.
local function check_file_exists(file_name)
	local file_path = get_file_path(file_name)
	return sys.exists(file_path)
end

-- Saves data that was written to a file.
-- Does not check if the file actually exists.
-- Returns nil.
local function save(file_name, data)
	local file_path = get_file_path(file_name)
	if sys.save(file_path, data) then
		unsaved_data[file_name] = nil
	else
		print("Defold Persist: save() -> Failed to save data: " .. file_path)
		print("                See the following documentation: https://defold.com/ref/sys/#sys.save:filename-table")
	end
end

--------------------------------------------------------------------------------
-- Module Functions
--------------------------------------------------------------------------------

-- Creates a file with the specified data.
-- If the file already exists, then its data can be overwritten.
-- Returns nil.
function persist.create(file_name, data, overwrite)
	if not check_file_exists(file_name) or overwrite then
		unsaved_data[file_name] = data
		save(file_name, data)
	else
		local file_path = get_file_path(file_name)
		print("Defold Persist: persist.create() -> File already exists: " .. file_path)
	end
end

-- Writes data to a file.
-- Returns nil.
function persist.write(file_name, key, value)
	if not check_file_exists(file_name) then
		local file_path = get_file_path(file_name)
		print("Defold Persist: persist.write() -> File does not exist: " .. file_path)
		return
	end
	if not unsaved_data[file_name] then
		unsaved_data[file_name] = {}
	end
	unsaved_data[file_name][key] = value
end

-- Flushes unsaved data from a file.
-- If a key is specified, then only that field is flushed.
-- Returns nil.
function persist.flush(file_name, key)
	if not check_file_exists(file_name) then
		local file_path = get_file_path(file_name)
		print("Defold Persist: persist.flush() -> File does not exist: " .. file_path)
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
-- Returns nil.
function persist.save(file_name)
	if not check_file_exists(file_name) then
		local file_path = get_file_path(file_name)
		print("Defold Persist: persist.save() -> File does not exist: " .. file_path)
		return
	end
	local data = persist.load(file_name)
	save(file_name, data)
end

-- Loads data from a file, including data that has not yet been saved.
-- Returns a table, or nil if the file does not exist.
function persist.load(file_name)
	local file_path = get_file_path(file_name)
	if not check_file_exists(file_name) then
		print("Defold Persist: persist.load() -> File does not exist: " .. file_path)
		return
	end
	local loaded_data = sys.load(file_path) or {}
	local unsaved_data = unsaved_data[file_name] or {}
	for key, value in pairs(unsaved_data) do
		loaded_data[key] = value
	end
	return loaded_data
end

return persist