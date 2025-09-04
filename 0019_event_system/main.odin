package main

import "core:fmt"
import "core:mem"
import "core:time"
import "core:strings"
import "core:container/queue"

EventType :: enum {
	Invalid,
	TextUpdate,
	PositionChange,
}

EventPayloadTextUpdate :: struct {
	text: string,
	// some relevant data..
}

EventPayloadPositionChange :: struct {
	pos: [2]f32,
}

EventPayload :: union {
	EventPayloadTextUpdate,
	EventPayloadPositionChange,
}

Event :: struct {
	type: EventType,
	payload: EventPayload,
}

TimedEvent :: struct {
	using event: Event,
	timer: f32,
}

EventCallbackProc :: proc(event: Event)

event_allocator: mem.Allocator
event_listeners: map[EventType][dynamic]EventCallbackProc
event_queue: queue.Queue(Event)
timed_event_queue: [dynamic]TimedEvent

event_type_subscribe :: proc(type: EventType, callback: EventCallbackProc) {
	if type not_in event_listeners {
		event_listeners[type] = make([dynamic]EventCallbackProc)
	}

	append(&event_listeners[type], callback)
}

event_publish :: proc(type: EventType, payload: EventPayload) {
	queue.enqueue(&event_queue, Event{
		type = type,
		payload = payload,
	})
}

timed_event_publish :: proc(type: EventType, payload: EventPayload, seconds: f32) {
	append(&timed_event_queue, TimedEvent{
		type = type,
		payload = payload,
		timer = seconds,
	})
}

process_events :: proc() {
	for queue.len(event_queue) > 0 {
		event := queue.dequeue(&event_queue)

		if listeners, ok := event_listeners[event.type]; ok {
			for callback in listeners {
				callback(event)
			}
		}
	}
}

process_timed_events :: proc(delta_time: f32) {
	// Reverse iteration so we can use unordered_remove
	for i := len(timed_event_queue) - 1; i >= 0; i -= 1 {
		event := &timed_event_queue[i]

		event.timer -= delta_time

		if event.timer <= 0 {
			if listeners, ok := event_listeners[event.type]; ok {
				for callback in listeners {
					callback(event)
				}
			}

			unordered_remove(&timed_event_queue, i)
		}
	}
}

main :: proc () {
	event_type_subscribe(.TextUpdate, event_text_update_callback_from_system_a)
	event_type_subscribe(.TextUpdate, event_text_update_callback_from_system_b)

	event_publish(.TextUpdate, EventPayloadTextUpdate{"new text"})

	timed_event_publish(.TextUpdate, EventPayloadTextUpdate{"hello from 3 seconds ago."}, 3)

	// -------------------------
	// Below is a fake game loop

	delta_time := f32(1) / 60 // 60 FPS
	delta_time_ns := delta_time * 1_000_000_000 // in nanoseconds

	// run for 5 seconds
	for _ in 0..<300 {
		process_events()
		process_timed_events(delta_time)

		// Sleep until next frame, simulate 60 FPS game
		time.sleep(time.Duration(delta_time_ns))
	}
}

event_text_update_callback_from_system_a :: proc(event: Event) {
	payload := event.payload.(EventPayloadTextUpdate)
	fmt.println("System A knows about text update:", payload.text)
}

event_text_update_callback_from_system_b :: proc(event: Event) {
	payload := event.payload.(EventPayloadTextUpdate)
	fmt.println("System B knows about text update:", payload.text)
}
