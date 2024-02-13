# Defold Persist

Defold Persist provides a simple interface for saving and loading data in a Defold game engine project.

Please click the ☆ button on GitHub if this repository is useful or interesting. Thank you!

![thumbnail.png](https://github.com/klaytonkowalski/library-defold-persist/blob/main/assets/images/thumbnail.png?raw=true)

## Installation

Add the latest version to your project's dependencies:  
https://github.com/klaytonkowalski/library-defold-persist/archive/main.zip

## Usage

Import Persist into script files that need to save or load data:

```
local persist = require "persist.persist"
```

A file must exist before it can be accessed, otherwise an error message will be printed to standard output. Let's create a settings file:

```
local default_settings_data =
{
    master_volume = 100,
    music_volume = 100,
    sound_volume = 100
}
persist.create("settings", default_settings_data)
```

If the settings file already exists, then `persist.create()` will simply be ignored. This function should be called as part of a project's startup routine for each file to ensure that it exists.

Each OS has its own conventions and preferences for where applications should create custom files. See the following list for details:

* Windows: C:\\Users\\\<user>\\AppData\\Roaming\\\<project_title>\\\<file_name>
* MacOS: ~/Library/Application Support/<project_title>/<file_name>
* (Please add a pull request for other platforms!)

Let's change the music volume from 100 to 75, and change the sound volume from 100 to 25:

```
persist.write("settings", "music_volume", 75)
persist.write("settings", "sound_volume", 25)
```

Persist keeps track of which data is *saved* and which data is *written*. Written data has not yet been transferred to non-volatile storage. It only exists as a table within the running process. This allows us to abort file changes before they overwrite previously saved data.

Let's revert back to whatever the sound volume was before we changed it, then save our changes:

```
persist.flush("settings", "sound_volume")
persist.save("settings")
```

Next let's load the settings data so that we know how loudly to play our wonderful background music:

```
local settings_data = persist.load("settings")
local master_volume = settings_data.master_volume
local music_volume = settings_data.music_volume
sound.play(msg.url(nil, nil, "background_music"), { gain = master_volume * music_volume })
```

When loading data, written data is prioritized over saved data. This means that `persist.load()` will always return the latest version of a file, even if it has not yet been saved.

## API

### persist.create(file_name, data [, overwrite])

Creates a file with the specified data. If the file already exists, then its data can be overwritten.

### persist.write(file_name, key, value)

Writes data to a file.

### persist.flush(file_name [, key])

Flushes unsaved data from a file. If a key is specified, then only that field is flushed.

### persist.save(file_name)

Saves data that was written to a file.

### persist.load(file_name)

Loads data from a file, including data that has not yet been saved.

### persist.exists(file_name)

Checks if a file exists.
