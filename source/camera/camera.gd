extends Camera2D

signal faded_out()
signal faded_in()

enum FadeMode {
	None,
	Out,
	In
}

@onready var color_rect = $CanvasLayer/ColorRect

var visibility := 1.0
var target_zoom := 1.0
var fade_mode := FadeMode.None

func _process(delta):
	var new_zoom = lerp(zoom.x, target_zoom, 1.0 - pow(0.06, delta))
	if abs(new_zoom - target_zoom) < 0.001:
		new_zoom = target_zoom
	zoom = Vector2(new_zoom, new_zoom)
	
	match fade_mode:
		FadeMode.Out:
			visibility = max(0, visibility - delta)
			if visibility == 0:
				fade_mode = FadeMode.In
				faded_out.emit()
			color_rect.material.set_shader_parameter("visibility", visibility)
		
		FadeMode.In:
			visibility = min(1, visibility + delta)
			if visibility == 1:
				fade_mode = FadeMode.None
				faded_in.emit()
			color_rect.material.set_shader_parameter("visibility", visibility)

func jump_to_zoom():
	zoom = Vector2(target_zoom, target_zoom)

func fade_out():
	fade_mode = FadeMode.Out
	await faded_out
