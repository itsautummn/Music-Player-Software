extends Node

signal on_ready_play_queue
signal change_audio
signal disable_prev
signal disable_next

@export var queue: Array[AudioStream]

var cur_queue_idx: int = 0

var loop: bool = false


func _ready() -> void:
	if (queue[cur_queue_idx] != null):
		on_ready_play_queue.emit(queue[cur_queue_idx])
		disable_prev.emit(true)
		if cur_queue_idx + 1 >= queue.size():
			disable_next.emit(true)


func _on_prev_texture_button_pressed() -> void:
	prev_song()


func _on_next_texture_button_pressed() -> void:
	next_song()
	

func prev_song() -> void:
	if not cur_queue_idx <= 0:
		cur_queue_idx -= 1
		change_audio.emit(queue[cur_queue_idx])
		check_queue_and_disable_skip_buttons()


func next_song() -> void:
	if not cur_queue_idx + 1 >= queue.size():
		cur_queue_idx += 1
		change_audio.emit(queue[cur_queue_idx])
		check_queue_and_disable_skip_buttons()


func check_queue_and_disable_skip_buttons() -> void:
	if cur_queue_idx <= 0:
		disable_prev.emit(true)
	else:
		disable_prev.emit(false)
		
	if cur_queue_idx + 1 >= queue.size():
		disable_next.emit(true)
	else:
		disable_next.emit(false)


func _on_loop_texture_button_toggled(toggled_on: bool) -> void:
	loop = toggled_on


func _on_audio_stream_player_finished() -> void:
	if loop:
		change_audio.emit(queue[cur_queue_idx])
	else:
		next_song()
