extends HSlider


func _ready() -> void:
	var linear: float = AudioServer.get_bus_volume_linear(AudioServer.get_bus_index("Master"))
	value = linear * 100


func _on_value_changed(value: float) -> void:
	AudioServer.set_bus_volume_linear(AudioServer.get_bus_index("Master"), value / 100)
	
