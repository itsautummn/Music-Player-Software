extends TextureButton

signal pressed_sig

@onready var pause_texture: Texture2D = preload('res://Assets/Audio Control/Pause.png')
@onready var pause_texture_highlight: Texture2D = preload('res://Assets/Audio Control/Pause Highlighted.png')
@onready var play_texture: Texture2D = preload('res://Assets/Audio Control/Play.png')
@onready var play_texture_highlight: Texture2D = preload('res://Assets/Audio Control/Play Highlighted.png')

var paused: bool = false

func _on_pressed() -> void:
	paused = !paused
	
	if paused:
		texture_normal = play_texture
		texture_hover = play_texture_highlight
	else:
		texture_normal = pause_texture
		texture_hover = pause_texture_highlight

	pressed_sig.emit(paused)


func _on_music_time_h_slider_drag_ended_sig(_value: float) -> void:
	unpause()


func _on_audio_queue_unpause() -> void:
	unpause()


func unpause() -> void:
	paused = false
	texture_normal = pause_texture
	texture_hover = pause_texture_highlight
