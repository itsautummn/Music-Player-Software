extends HSlider

var previous_vol_before_mute: float


func _ready() -> void:
	var linear: float = AudioServer.get_bus_volume_linear(AudioServer.get_bus_index("Master"))
	value = linear * 100
	previous_vol_before_mute = value
	print(previous_vol_before_mute)


func _on_value_changed(slider_value: float) -> void:
	AudioServer.set_bus_volume_linear(AudioServer.get_bus_index("Master"), slider_value / 100)
	

func _on_volume_h_box_container_volume_mute(muted: bool) -> void:
	if muted:
		previous_vol_before_mute = value
		value = 0.0
	else:
		value = previous_vol_before_mute
