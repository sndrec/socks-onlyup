extends TextureRect

func _ready() -> void:
	_on_mario_health_wedges_changed(8)

func _on_mario_health_wedges_changed(health_wedges: int) -> void:
	var hue : float = [0.0, 0.0, 0.05, 0.11, 0.18, 0.27, 0.37, 0.47, 0.57][clamp(health_wedges, 0, 8)]
	var base_saturation := 0.0 if health_wedges == 0 else 1.0
	var base_value := 0.4 if health_wedges == 0 else 1.0
	material.set_shader_parameter("outlineColor",         Color.from_hsv(hue, base_saturation * 0.75, base_value))
	material.set_shader_parameter("topGradientCheck1",    Color.from_hsv(hue, base_saturation * 0.8,  base_value * 0.75))
	material.set_shader_parameter("bottomGradientCheck1", Color.from_hsv(hue, base_saturation * 0.8,  base_value * 0.5))
	material.set_shader_parameter("topGradientCheck2",    Color.from_hsv(hue, base_saturation,        base_value * 0.5))
	material.set_shader_parameter("bottomGradientCheck2", Color.from_hsv(hue, base_saturation,        base_value * 0.25))
