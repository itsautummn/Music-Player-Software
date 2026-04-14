# Plan:
# 	Will read the Music folder (Windows) and import all .mp3 files (for now) raw data into AudioStream resources
# Todo:
#	- Create modular folder naviagtion system
#	- Open Music directory
#	- Open all files in directory (shallow for now)
#	- Read file data directly into AudioStream resources
#	- Create music select elements from the AudioStream resources
# 	- Populate 
extends Control

@export var anim_speed: float = 0.1
@export var tab_container: TabContainer
@export var album_select_container: VBoxContainer
@export var playlist_select_container: VBoxContainer
@export var liked_select_container: VBoxContainer
@export var unsorted_select_container: VBoxContainer
@export var music_select_element_scene: PackedScene = preload("res://music_select_element.tscn")

var queue: Array[AudioStream]
var opened: bool = false
var current_select_container: VBoxContainer


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
	unsorted_select_container.add_child(music_element)
	print(unsorted_select_container.get_children())


func _on_open_button_pressed() -> void:
	print("opened!!")
	var tween: Tween = create_tween()
	
	if opened:
		tween.tween_property(self, "position", Vector2(self.position.x - tab_container.size.x, self.position.y), anim_speed)
	else:
		tween.tween_property(self, "position", Vector2(self.position.x + tab_container.size.x, self.position.y), anim_speed)
	
	opened = not opened


func _on_tab_container_tab_changed(tab: int) -> void:
	match (tab):
		0:
			current_select_container = album_select_container
		1:
			current_select_container = playlist_select_container
		2:
			current_select_container = liked_select_container
		3:
			current_select_container = unsorted_select_container
		_:
			printerr("Tab %s not recognized" % tab)
