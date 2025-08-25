package main

import "core:fmt"
import "core:os"
import "core:strconv"
import "core:encoding/ini"

import rl "vendor:raylib"

config_default_fmt :: `
[bindings]
Jump = %s
Sprint = %s
Left = %s
Right = %s
`

CONFIG_PATH :: "config.ini"

config_load_and_apply :: proc(input_map: ^[GameBinding]rl.KeyboardKey) {
	is_config_valid := false
	m: ini.Map
	
	// Load existing config file
	if os.exists(CONFIG_PATH) {
		ini_map, err, ok := ini.load_map_from_path(CONFIG_PATH, context.temp_allocator)
		if err == .None && ok {
			// TODO: Verify your game's config file
			is_config_valid = true
			m = ini_map
		}
	}

	// Rewrite default config file
	if !is_config_valid {
		config_default := fmt.tprintf(
			config_default_fmt[1:],
			string_from_key(.SPACE),
			string_from_key(.LEFT_SHIFT),
			string_from_key(.A),
			string_from_key(.D),
		)
		os.write_entire_file(CONFIG_PATH, transmute([]u8)config_default)

		ini_map, err := ini.load_map_from_string(config_default, context.temp_allocator)
		if err == .None {
			m = ini_map
		}
	}

	// Apply the config
	{
		input_map[.Jump] = key_from_string(m["bindings"]["Jump"])
		input_map[.Sprint] = key_from_string(m["bindings"]["Sprint"])
		input_map[.Left] = key_from_string(m["bindings"]["Left"])
		input_map[.Right] = key_from_string(m["bindings"]["Right"])
	}
}

string_from_key :: proc(key: rl.KeyboardKey, scratch := context.temp_allocator) -> string {
	if key >= .A && key <= .Z {
		return fmt.aprintf("%c", u8(key), allocator = scratch)
	}

	#partial switch key {
	case .SPACE: return "SPACE"
	case .LEFT_SHIFT: return "LEFT_SHIFT"
	// ...
	}

	return "NULL"
}

key_from_string :: proc(s: string) -> rl.KeyboardKey {
	if len(s) == 1 {
		return rl.KeyboardKey(u8(s[0]))
	}

	switch s {
	case "SPACE": return .SPACE
	case "LEFT_SHIFT": return .LEFT_SHIFT
	// ...
	}

	return .KEY_NULL
}
