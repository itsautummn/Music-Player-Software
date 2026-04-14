extends HBoxContainer

@onready var current_time_label: Label = $CurrentTimeLabel
@onready var total_time_label: Label = $TotalTimeLabel

func _on_audio_stream_player_update_playback_position(current_time: float, total_length: float) -> void:
	var cur_sec: int = sec_modulo_min(current_time)
	var cur_min: int = sec_to_min(current_time)
	var tol_sec: int = sec_modulo_min(total_length)
	var tol_min: int = sec_to_min(total_length)
	current_time_label.text = format_time_to_string(cur_sec, cur_min)
	total_time_label.text = format_time_to_string(tol_sec, tol_min)


func sec_to_min(seconds: float) -> int:
	return floor(seconds / 60)


func sec_modulo_min(seconds: float) -> int:
	@warning_ignore("narrowing_conversion")
	return fmod(seconds, 60)


func format_time_to_string(seconds: int, minutes: int) -> String:
	if (seconds < 10):
		return "%d:0%d" % [minutes, seconds]
	return "%d:%d" % [minutes, seconds]
