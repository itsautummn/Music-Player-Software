extends Control

var spectrum_analyzer: AudioEffectInstance = null

func _ready() -> void:
	spectrum_analyzer = AudioServer.get_bus_effect_instance(AudioServer.get_bus_index("Master"), 0)


func _process(_delta: float) -> void:
	var frequency_range: Vector2 = spectrum_analyzer.get_magnitude_for_frequency_range(0.0, 20000.0, 1)
	print(frequency_range)
