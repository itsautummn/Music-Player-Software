extends HSlider

signal drag_ended_sig

var dragging: bool = false


func _on_audio_stream_player_update_playback_position(current_time: float, total_length: float) -> void:
	if not dragging:
		self.value = (current_time / total_length) * 100


func _on_drag_started() -> void:
	dragging = true


func _on_drag_ended(_value_changed: bool) -> void:
	dragging = false
	drag_ended_sig.emit(value)
