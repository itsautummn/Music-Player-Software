extends Control

const LINE_WIDTH: int = 1
const LINE_SPACING: int = 5
const NUM_LINES: int = 64

const MAX_FREQ: int = 11050 # Frequency range to analyze

var spectrum_instance: AudioEffectInstance
var top_lines: Array[ColorRect] = []
var bot_lines: Array[ColorRect] = []
var gradient: Gradient = Gradient.new()

# Spectrum Customization
@export_category('Spectrum Color')
@export var base_color: Color = Color.WHITE
@export var use_color_gradient: bool = true
@export var color_gradient: Gradient
@export var color_intensity: float = 1000.0

@export_category('Spectrum Magnitude')
@export var MAG_SCALE: float = 250.0
@export_subgroup('Clamp')
@export var CLAMP_MAG_SCALE: bool = true
@export var clamp_mag_scale_max: float = 50.0

@export_category('Misc')
@export var ANIM_SPEED: float = 0.1
@export var volume_affects_magnitude: bool = true


func _ready() -> void:
	spectrum_instance = AudioServer.get_bus_effect_instance(AudioServer.get_bus_index("Master"), 0)
	create_lines()


func create_lines() -> void:
	for i in range(NUM_LINES):
		var top_line: ColorRect = ColorRect.new()
		var bot_line: ColorRect = ColorRect.new()
		top_line.color = base_color
		bot_line.color = base_color
		
		var total_length: float = LINE_SPACING * NUM_LINES
		var position_offset: float = total_length / 2
		top_line.size = Vector2(LINE_WIDTH, 50) # Adjust line size
		bot_line.size = Vector2(LINE_WIDTH, 50) # Adjust line size
		top_line.position = Vector2(i * LINE_SPACING - position_offset, 0) # Space lines apart
		bot_line.position = Vector2(i * LINE_SPACING - position_offset, 0) # Space lines apart
		add_child(top_line)
		add_child(bot_line)
		top_lines.append(top_line)
		bot_lines.append(bot_line)
		

func _process(_delta: float) -> void:
	if not spectrum_instance:
		return
	
	var max_freq_amp: float = top_lines.reduce(func(m, b): return b if b.size.y > m.size.y else m).size.y
	
	for i in range(NUM_LINES):
		var freq_start: float = (i * MAX_FREQ) / float(NUM_LINES)
		var freq_end: float = ((i + 1) * MAX_FREQ) / float(NUM_LINES)
		var magnitude: float = spectrum_instance.get_magnitude_for_frequency_range(freq_start, freq_end).length()
		
		magnitude = magnitude * AudioServer.get_bus_volume_linear(AudioServer.get_bus_index("Master")) if volume_affects_magnitude else magnitude
		
		if CLAMP_MAG_SCALE:
			top_lines[i].size.y = clampf(lerp(top_lines[i].size.y, magnitude * MAG_SCALE * 2, ANIM_SPEED), 0.0, clamp_mag_scale_max)
		else:
			top_lines[i].size.y = lerp(top_lines[i].size.y, magnitude * MAG_SCALE * 2, ANIM_SPEED)
		bot_lines[i].size.y = top_lines[i].size.y
		bot_lines[i].scale.y = -1
		
		if use_color_gradient:
			var intensity: float = (magnitude * color_intensity) / (max_freq_amp * color_intensity) if max_freq_amp > 0.0 else 0.0
			intensity *= color_intensity
			intensity = clamp(intensity, 0.0, 1.0) # Keep within a valid range
			
			# Get dynamic color from gradient
			var new_color = color_gradient.sample(intensity)
			top_lines[i].color = new_color
			bot_lines[i].color = new_color
		else:
			top_lines[i].color = base_color
			bot_lines[i].color = base_color
