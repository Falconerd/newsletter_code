package main

import "core:fmt"
import "core:os"
import "core:encoding/ini"

import rl "vendor:raylib"

config_default_fmt :: `
[bindings]
Jump = %d
Sprint = %d
Left = %d
Right = %d
`

config_load :: proc(input_map: [GameBinding]rl.KeyboardKey) {
	ini_map, err, ok := ini.load_map_from_path("config.ini", context.temp_allocator)
	if !ok || err != .None {
		// Create default config file?
		config_default := fmt.tprintf(config_default_fmt, rl.KeyboardKey.SPACE, rl.KeyboardKey.LEFT_SHIFT, rl.KeyboardKey.A, rl.KeyboardKey.D)
		os.write_entire_file("config.ini", transmute([]u8)config_default)
	}
}
