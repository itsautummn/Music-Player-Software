extends Control

@export var anim_speed: float = 0.1
@export var music_select_vbox_container: VBoxContainer
@export var music_select_element_scene: PackedScene = preload("res://music_select_element.tscn")

var queue: Array[AudioStream]
var opened: bool = false


func _on_audio_queue_send_queue(sent_queue: Array[AudioStream]) -> void:
	populate_queue_setup(sent_queue)


func populate_queue_setup(sent_queue: Array[AudioStream]) -> void:
	queue = sent_queue
	for i in range(queue.size()):
		var decoder: ID3v2Decoder = ID3v2Decoder.new()
		decoder.send_out_metadata.connect(populate_queue_data)
		decoder.read_metadata(queue[i])
		#var metadata_dict: Dictionary = decoder.read_and_release_metadata(queue[i])
	

func populate_queue_data(metadata_dict: Dictionary) -> void:
	var music_element: MusicElement = music_select_element_scene.instantiate()
	music_element.init(metadata_dict['title'], metadata_dict['artist'], metadata_dict['length'])
	music_select_vbox_container.add_child(music_element)


func _on_open_button_pressed() -> void:
	var tween: Tween = create_tween()
	@warning_ignore("standalone_ternary")
	tween.tween_property(self, "position", Vector2(position.x + $ContentPanelContainer.size.x, position.y), anim_speed) if not opened else tween.tween_property(self, "position", Vector2(position.x - $ContentPanelContainer.size.x, position.y), anim_speed)
	opened = not opened
