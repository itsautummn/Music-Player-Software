# Author: Autumn Simpson
# Last Updated: 4/3/2026
# Description:
# 	Checks .mp3 file metadata for an ID3v2 tag and populates basic data if found
# 	Sends out a signal when 'read_metadata()' is called that contains a dictionary of data
# 	If a frame was not found when parsing metadata, the dictionary value of that key will be empty
# 	Compatible with ID3v2.3 and ID3v2.4 metadata tags
# 	Reads and releases the following frame data in this order:
# 	> Title of Track
# 	> Album
# 	> Track Number
# 	> Artist
# 	> Album Picture
# 	> Release Date
# 	> Track Length
# 	> Comments

class_name ID3v2Decoder
extends Node

signal send_out_metadata(metadata: Dictionary)

# Metadata Variables
var _title: String
var _album: String
var _track_number: String
var _artist: String
var _album_picture: Image
var _release_date: String
var _length: String
var _comments: String


# Helper Functions
func _read_bits(byte: int) -> void:
	for i in range(8):
		var bit = (byte >> i) & 1
		print("  Bit %s is: %s" % [i, bit])


func _syncsafe_to_int(bytes: PackedByteArray) -> int:
	if bytes.size() != 4:
		return 0
	
	var res = 0
	res |= bytes[0] << 21
	res |= bytes[1] << 14
	res |= bytes[2] << 7
	res |= bytes[3]
	
	return res


func read_metadata(audio: AudioStream) -> void:
	var path: String = audio.resource_path
	
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	
	# Read 10 byte header 
	# File Identifier (3 Bytes) & Version (2 Bytes) (we have to get the major version first to support the proper encoding type)
	var file_identifier_bytes: PackedByteArray = file.get_buffer(3)
	var major_version: int = file.get_8()
	var _revision_number: int = file.get_8()
	var file_identifier: String = _get_string_from_proper_encode_type(file_identifier_bytes, major_version)
	if file_identifier != 'ID3' and (major_version != 3 or major_version != 4):
		print('ERROR: Provided MP3 file does not include an ID3v2.3 or ID3v2.4 metadata tag')
		_reset_metadata_variables()
		_release_metadata()
		return
	# Flags (1 Byte)
	var _flags: int = file.get_8()
	# Size (4 Bytes)
	var size_bytes: PackedByteArray = file.get_buffer(4)
	var size: int = _syncsafe_to_int(size_bytes)
	
	# > Read first frame to see if I can actually do this
	# > Looks like I can :D
	
	while file.get_position() < size:
		# Read frame header
		# Frame ID
		var frame_ID_bytes: PackedByteArray = file.get_buffer(4)
		var frame_ID: String = _get_string_from_proper_encode_type(frame_ID_bytes, major_version)
		if frame_ID == "": # Break statement
			break
		# Frame Size
		var frame_size_bytes: PackedByteArray = file.get_buffer(4)
		var frame_size: int
		if major_version == 3:
			# ID3v2.3 uses plain 32-bit integer (big-endian)
			frame_size = (frame_size_bytes[0] << 24) | (frame_size_bytes[1] << 16) | (frame_size_bytes[2] << 8) | frame_size_bytes[3]
		elif major_version == 4:
			# ID3v2.4 uses syncsafe integer
			frame_size = _syncsafe_to_int(frame_size_bytes)
		else:
			print('ERROR: Major version not supported!')
		# Frame flags
		var _frame_flags: int = file.get_16()
		
		# Read the frame data itself and populate respective variables
		_parse_metadata_frames(file, frame_ID, frame_size, major_version)
		
	# Send out the signal with the metadata dictionary
	_release_metadata()


func _parse_metadata_frames(file: FileAccess, frame_ID: String, frame_size: int, major_version: int) -> void:
	# Frame data is different per frame, so parse data individually based on what we want/need
	match frame_ID:
		'TIT2': # Title
			var frame_data_bytes: PackedByteArray = file.get_buffer(frame_size)
			_title = _decode_text_frame(frame_data_bytes, major_version)
		'TALB': # Album
			var frame_data_bytes: PackedByteArray = file.get_buffer(frame_size)
			_album = _decode_text_frame(frame_data_bytes, major_version)
		'TRCK': # Track number
			var frame_data_bytes: PackedByteArray = file.get_buffer(frame_size)
			_track_number = _decode_text_frame(frame_data_bytes, major_version)
		'TPE1': # Artist
			var frame_data_bytes: PackedByteArray = file.get_buffer(frame_size)
			_artist = _decode_text_frame(frame_data_bytes, major_version)
		'APIC': # Album picture
			_parse_APIC_frame_data(file, frame_size, major_version)
		'TDRC': # Release date
			var frame_data_bytes: PackedByteArray = file.get_buffer(frame_size)
			_release_date = _decode_text_frame(frame_data_bytes, major_version)
		'TLEN': # Length in seconds
			var frame_data_bytes: PackedByteArray = file.get_buffer(frame_size)
			_length = _decode_text_frame(frame_data_bytes, major_version)
		'COMM': # Comments (done different because they are stored differently)
			_parse_COMM_frame_data(file, frame_size, major_version)
		_:
			var _frame_data_bytes: PackedByteArray = file.get_buffer(frame_size)


func _parse_APIC_frame_data(file: FileAccess, frame_size: int, major_version: int) -> void:
	# Read the entire frame data first
	var frame_data_bytes: PackedByteArray = file.get_buffer(frame_size)
	var pos: int = 0 # Track position within frame_data_bytes
	
	if frame_data_bytes.size() < 1:
		print('APIC frame too small')
		return
	
	# Text encoding (1 Byte)
	var text_encoding: int = frame_data_bytes[pos]
	pos += 1
	
	# MIME type (null-terminated string)
	var mime_type_bytes: PackedByteArray
	while pos < frame_data_bytes.size():
		var byte = frame_data_bytes[pos]
		pos += 1
		if byte == 0:
			break
		mime_type_bytes.append(byte)		
	var mime_type: String = mime_type_bytes.get_string_from_ascii()
	
	# Check if we've gone past the buffer
	if pos >= frame_data_bytes.size():
		print('APIC frame: Reached end before reading picture type')
		return
	
	# Picture type (1 byte)
	var _picture_type: int = frame_data_bytes[pos]
	pos += 1
	
	# Description (null-terminated string, uses text_encoding)
	var description_bytes: PackedByteArray
	var _description: String
	if text_encoding == 0: # ISO-8895-1
		while pos < frame_data_bytes.size():
			var byte = frame_data_bytes[pos]
			pos += 1
			if byte == 0:
				break
			description_bytes.append(byte)
		_description = description_bytes.get_string_from_ascii()
	else: # UTF-16
		while pos < frame_data_bytes.size() - 1:
			var byte1 = frame_data_bytes[pos]
			var byte2 = frame_data_bytes[pos + 1]
			pos += 2
			if byte1 == 0 and byte2 == 0:
				break
			description_bytes.append(byte1)
			description_bytes.append(byte2)
		# Decode UTF-16 description
		_description = _decode_text_frame(PackedByteArray([text_encoding]) + description_bytes, major_version)
	
	# Remaining bytes are the picture data
	var picture_data: PackedByteArray = frame_data_bytes.slice(pos)
	
	# Create image from picture data
	match mime_type:
		'image/jpeg':
			_album_picture = Image.new()
			var error = _album_picture.load_jpg_from_buffer(picture_data)
			if error != OK:
				print('Failed to load JPEG: Error code %d' % error)
				print('First few bytes of picture data: ', picture_data.slice(0, min(16, picture_data.size())))
				_album_picture = null
		'image/png':
			_album_picture = Image.new()
			var error = _album_picture.load_png_from_buffer(picture_data)
			if error != OK:
				print('Failed to load PNG: Error code %d' % error)
				_album_picture = null
		_:
			print('Unknown picture type: %s' % mime_type)


func _parse_COMM_frame_data(file: FileAccess, frame_size: int, major_version: int) -> void:
	var frame_data_bytes: PackedByteArray = file.get_buffer(frame_size)
			
	var encoding: int = frame_data_bytes[0]
	# Langauge is 3 bytes, ISO-639-2, not null-terminated
	var language_bytes: PackedByteArray = frame_data_bytes.slice(1, 4)
	var _language: String = language_bytes.get_string_from_ascii()
	
	# Skip encoding (1) + language (3) = 4 bytes
	var remaining: PackedByteArray = frame_data_bytes.slice(4)
	
	# Find the double null or signel null terminator for description
	var desc_end: int = -1
	if encoding == 0: # ISO-8859-1
		desc_end = remaining.find(0)
		if desc_end != -1:
			remaining = remaining.slice(desc_end + 1)
	else: # UTF-16
		for i in range(0, remaining.size() - 1, 2):
			if remaining[i] == 0 and remaining[i + 1] == 0:
				desc_end = i
				break
		if desc_end != -1:
			remaining = remaining.slice(desc_end + 2)
	
	# Remaining is the actual comment text (with its own encoding byte)
	if remaining.size() > 0:
		_comments = _decode_text_frame(PackedByteArray([encoding]) + remaining, major_version)


# Used to find the file identifier and frame ID's because it only checks major version and not the first byte encode
func _get_string_from_proper_encode_type(bytes: PackedByteArray, major_version: int) -> String:
	if major_version == 3:
		return bytes.get_string_from_ascii()
	elif major_version == 4:
		return bytes.get_string_from_utf8()
	else:
		print('ERROR: ID3v2 Major version %s not recognized!' % major_version)
	return ''


# Used to find the frame data because it checks both major version and first byte encode
func _decode_text_frame(frame_data: PackedByteArray, major_version: int) -> String:
	if frame_data.size() == 0:
		return ''
	
	# Get encoding byte (first byte)
	var encoding: int = frame_data[0]
	var string_bytes: PackedByteArray = frame_data.slice(1)
	
	# Find null terminator(s) based on encoding
	var null_pos: int = -1
	if encoding == 0: # ISO-8859-1
		null_pos = string_bytes.find(0)
		if null_pos != -1:
			string_bytes = string_bytes.slice(0, null_pos)
		return string_bytes.get_string_from_ascii()
	
	elif encoding == 1: # UTF-16 with BOM
		# Check for BOM (FF FE or FE FF)
		var is_little_endian: bool = true
		
		if string_bytes.size() >= 2:
			if string_bytes[0] == 0xFF and string_bytes[1] == 0xFE:
				is_little_endian = true
				string_bytes = string_bytes.slice(2)
			elif string_bytes[0] == 0xFE and string_bytes[1] == 0xFF:
				is_little_endian = false
				string_bytes = string_bytes.slice(2)
			
		# Find double null terminator
		for i in range(0, string_bytes.size() - 1, 2):
			if string_bytes[i] == 0 and string_bytes[i + 1] == 0:
				string_bytes = string_bytes.slice(0, i)
				break
		
		# Convert UTF16 bytes to string
		var utf16_string = ''
		for i in range(0, string_bytes.size(), 2):
			if i + 1 < string_bytes.size():
				var char_code: int
				if is_little_endian:
					char_code = string_bytes[i] | (string_bytes[i + 1] << 8)
				else:
					char_code = (string_bytes[i] << 8) | string_bytes[i + 1]
				utf16_string += char(char_code)
		return utf16_string
	
	elif major_version == 4 and encoding == 2: # UTF-16BE (v2.4 only)
		# Find double null terminator
		for i in range(0, string_bytes.size() - 1, 2):
			if string_bytes[i] == 0 and string_bytes[i + 1] == 0:
				string_bytes = string_bytes.slice(0, i)
				break
		
		var utf16be_string = ''
		for i in range(0, string_bytes.size(), 2):
			if i + 1 < string_bytes.size():
				var char_code: int = (string_bytes[i] << 8) | string_bytes[i + 1]
				utf16be_string += char(char_code)
		return utf16be_string
	
	elif major_version == 4 and encoding == 3: # UTF-8 (v2.4 only)
		null_pos = string_bytes.find(0)
		if null_pos != -1:
			string_bytes = string_bytes.slice(0, null_pos)
		return string_bytes.get_string_from_utf8()
	
	return 'ERROR: decode_frame_text() not working!'


func _release_metadata() -> void:
	var metadata_dict: Dictionary = {
		'title': _title,
		'album': _album,
		'track_number': _track_number,
		'artist': _artist,
		'album_picture': _album_picture,
		'release_date': _release_date,
		'length': _length,
		'comments': _comments
	}
	
	send_out_metadata.emit(metadata_dict)
	_reset_metadata_variables()


func _reset_metadata_variables() -> void:
	_title = ''
	_album = ''
	_track_number = ''
	_artist = ''
	_album_picture = null
	_release_date = ''
	_length = ''
	_comments = ''


func read_and_release_metadata(audio: AudioStream) -> Dictionary:
	read_metadata(audio)
	var metadata_dict: Dictionary = {
		'title': _title,
		'album': _album,
		'track_number': _track_number,
		'artist': _artist,
		'album_picture': _album_picture,
		'release_date': _release_date,
		'length': _length,
		'comments': _comments
	}
	print(metadata_dict)
	return metadata_dict
