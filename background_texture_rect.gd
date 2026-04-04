extends TextureRect


func _set(property: StringName, value: Variant) -> bool:
	if property == "texture":
		texture = value
		material.set_shader_parameter("texture_to_apply", texture)
	return true
