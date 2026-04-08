extends Node

signal change_audio
signal disable_prev
signal disable_next
signal unpause
signal send_queue(queue: Array[AudioStream])

@export var queue: Array[AudioStream]

var cur_queue_idx: int = 0

var loop: bool = false


func _ready() -> void:
	play_first_song_in_queue()
	send_out_queue()
	

func play_first_song_in_queue() -> void:
	if (queue[0] != null):
		change_audio.emit(queue[0])
		disable_prev.emit(true)
		if 1 >= queue.size():
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
		unpause.emit()


func next_song() -> void:
	if not cur_queue_idx + 1 >= queue.size():
		cur_queue_idx += 1
		change_audio.emit(queue[cur_queue_idx])
		check_queue_and_disable_skip_buttons()
		unpause.emit()


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


func send_out_queue() -> void:
	send_queue.emit(queue)
