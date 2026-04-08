class_name MusicElement
extends Control

signal pressed

@export var file_type_texture_rect: TextureRect
@export var title_label: Label
@export var artist_label: Label
@export var length_label: Label
var audio_stream: AudioStream

var mouse_hovering: bool = false


func init(title: String, artist: String, length: String) -> void:
	#file_type_texture_rect.texture = _____
	title_label.text = title
	artist_label.text = artist
	length_label.text = format_time_to_string(length.to_float())
	#audio_stream = audio


func _on_mouse_entered() -> void:
	mouse_hovering = true


func _on_mouse_exited() -> void:
	mouse_hovering = false


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_select_mouse"):
		pressed.emit()


func sec_to_min(seconds: float) -> int:
	return floor(seconds / 60)


func sec_modulo_min(seconds: float) -> int:
	@warning_ignore("narrowing_conversion")
	return fmod(seconds, 60)


func format_time_to_string(seconds: float) -> String:
	var _sec: int = sec_modulo_min(seconds)
	var _min: int = sec_to_min(seconds)
	if (seconds < 10):
		return "%d:0%d" % [_min, _sec]
	return "%d:%d" % [_min, _sec]
