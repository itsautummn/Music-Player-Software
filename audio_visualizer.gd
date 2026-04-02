extends Control

@export var vboxcontainer: VBoxContainer

const VU_COUNT: int = 32 # Number of drawn lines
const FREQ_MAX: float = 11050.0 # Seems arbitrary but idk yet

const MIN_DB: int = 60 #db
const HEIGHT: int = 100 #px?
const HEIGHT_SCALE: float = 10.0
const ANIMATION_SPEED: float = 0.1

var WIDTH: float #px?

var spectrum_analyzer: AudioEffectInstance = null
var min_values: Array[float] = []
var max_values: Array[float] = []

var do_process: bool = true

func _ready() -> void:
	WIDTH = vboxcontainer.size.x
	
	spectrum_analyzer = AudioServer.get_bus_effect_instance(AudioServer.get_bus_index("Master"), 0)
	min_values.resize(VU_COUNT)
	max_values.resize(VU_COUNT)
	min_values.fill(0.0)
	max_values.fill(0.0)
	
	

func _draw() -> void:
	@warning_ignore("integer_division") # There are literally no floats in this equation I don't know what its freaking out about
	var line_width: float = WIDTH / VU_COUNT
	
	for i in range(VU_COUNT):
		var min_height: float = min_values[VU_COUNT - 1 - i]
		var max_height: float = max_values[VU_COUNT - 1 - i]
		var height: float = lerp(min_height, max_height, ANIMATION_SPEED)
		
		var line_pos_x: float = (line_width * i) - (vboxcontainer.size.x / 2) + (line_width / 2)
		
		draw_line(
			Vector2(line_pos_x, -(HEIGHT - height)),
			Vector2(line_pos_x, (HEIGHT - height)),
			Color.WHITE,
			1.0,
			true
		)


func _process(_delta: float) -> void:		
	var data: Array[float] = []
	var prev_hz: float = 0
	
	for i in range(1, VU_COUNT + 1):
		var hz: float = i * FREQ_MAX / VU_COUNT
		var magnitude_vec: Vector2 = spectrum_analyzer.get_magnitude_for_frequency_range(prev_hz, hz)
		var magnitude: float = magnitude_vec.length()
		var energy: float = clampf((MIN_DB + linear_to_db(magnitude)) / MIN_DB, 0, 1)
		var height: float = energy * HEIGHT * HEIGHT_SCALE
		if do_process:
			data.append(height)
		else:
			data.append(0.0)
		prev_hz = hz
	
	for i in range(VU_COUNT):
		if data[i] > max_values[i]:
			max_values[i] = data[i]
		else:
			max_values[i] = lerp(max_values[i], data[i], ANIMATION_SPEED)
		
		if data[i] <= 0.0:
			min_values[i] = lerp(min_values[i], float(HEIGHT), ANIMATION_SPEED)
	
	# Sound plays back continuously, so the graph needs to be updated every frame
	queue_redraw()


func _on_pause_unpause(paused: bool) -> void:
	do_process = !paused
