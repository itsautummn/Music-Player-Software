extends HBoxContainer

signal volume_mute

var muted: bool = false


func _on_volume_texture_rect_pressed() -> void:
	muted = !muted
	
	if muted:
		volume_mute.emit(true)
	else:
		volume_mute.emit(false)
