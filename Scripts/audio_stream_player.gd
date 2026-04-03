extends AudioStreamPlayer

signal update_playback_position
signal unpaused

var loop: bool = false


func _process(_delta: float) -> void:
	update_playback_position.emit(get_playback_position(), stream.get_length())


func _on_music_time_h_slider_drag_ended_sig(value: float) -> void:
	play((value / 100) * stream.get_length())


func _on_play_texture_button_pressed_sig(paused: bool) -> void:
	stream_paused = paused


func _on_audio_queue_change_audio(audio: AudioStream) -> void:
	stream = audio
	play()
