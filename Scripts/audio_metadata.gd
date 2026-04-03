extends Node

@onready var missing_album_cover_texture: Texture2D = preload("res://Assets/Missing Album Cover.png")

@export_category('ID3v2 Decoder')
@export var id3v2_decoder: ID3v2Decoder

@export_category('UI To Populate')
@export var cover_texture_rect: TextureRect
@export var title_label: Label
@export var artist_label: Label
@export var album_label: Label
@export var track_number_label: Label

# Metadata Variables
var title: String
var album: String
var track_number: String
var artist: String
var album_picture: Image
var release_date: String
var length: String
var comments: String


func _ready() -> void:
	cover_texture_rect.texture = missing_album_cover_texture


func send_out_metadata() -> void:
	cover_texture_rect.texture = ImageTexture.create_from_image(album_picture) if album_picture else missing_album_cover_texture
	title_label.text = title if title else 'Unknown Title'
	artist_label.text = artist if artist else 'Unknown Artist'
	album_label.text = album if album else 'Unknown Album'
	track_number_label.text = '| ' + format_track_number() if track_number else ''
	
	# Clear metadata so no residual data appears on a wrong song
	album_picture = null
	title = ''
	artist = ''
	album = ''
	track_number = ''


func _on_id3v2_reader_send_out_metadata(metadata: Dictionary) -> void:
	title = metadata['title']
	album = metadata['album']
	track_number = metadata['track_number']
	artist = metadata['artist']
	album_picture = metadata['album_picture']
	release_date = metadata['release_date']
	length = metadata['length']
	comments = metadata['comments']
	
	send_out_metadata()


func _on_audio_queue_change_audio(audio: AudioStream) -> void:
	id3v2_decoder.read_metadata(audio)


func format_track_number() -> String:
	var track_position: String = track_number.get_slice('/', 0)
	var album_length: String = track_number.get_slice('/', 1)
	return 'Track %s of %s' % [track_position, album_length]


func sec_to_min(seconds: float) -> int:
	return floor(seconds / 60)


func sec_modulo_min(seconds: float) -> int:
	return int(fmod(seconds, 60))


func format_time_to_string(sec: float) -> String:
	var sec_int: int = sec_modulo_min(sec)
	var min_int: int = sec_to_min(sec)
	if (sec_int < 10):
		return "%d:0%d" % [min_int, sec_int]
	return "%d:%d" % [min_int, sec_int]
