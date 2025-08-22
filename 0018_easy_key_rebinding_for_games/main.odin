package main

import "core:fmt"
import rl "vendor:raylib"
import sdl "vendor:sdl3"

InputState :: enum {
	Up,
	Pressed,
	Down,
	Released,
}

GameBinding :: enum {
	Jump,
	Sprint,
	Left,
	Right,
}

input_map: [GameBinding]rl.KeyboardKey
input_state: [GameBinding]InputState

input_update :: proc() {
	for key, binding in input_map {
		if rl.IsKeyPressed(key) {
			input_state[binding] = .Pressed
		} else if rl.IsKeyDown(key) {
			input_state[binding] = .Down
		} else if rl.IsKeyReleased(key) {
			input_state[binding] = .Released
	 	} else {
			input_state[binding] = .Up
	 	}
	}
}

input_update_sdl3 :: proc() {
	event: sdl.Event
	for sdl.PollEvent(&event) {
		#partial switch event.type {
		case .KEY_DOWN:
			// Check if key was already down, etc
		case .KEY_UP:
			// ...
		}
	}
}

main :: proc() {
	window_size := rl.Vector2{1280, 720}

	rl.InitWindow(i32(window_size.x), i32(window_size.y), "My Game")

	font := rl.LoadFont("dwarven_axe.ttf")
	font_size :: 48

	config_load(input_map)

	for !rl.WindowShouldClose() {
		input_update()

		text := fmt.ctprintf("%v", input_state)
		text_size := rl.MeasureTextEx(font, text, font_size, 0)

		rl.BeginDrawing()
		rl.ClearBackground({0, 0, 19, 255})

		rl.DrawTextEx(font, text, (window_size - text_size) / 2, font_size, 0, rl.WHITE)

		rl.EndDrawing()
	}
}
