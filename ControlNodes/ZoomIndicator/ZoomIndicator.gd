extends VSlider

var camera
var playerEntered = false
func _ready():
	camera = get_tree().get_nodes_in_group("Camera")[0]
	min_value = camera.minHeight
	max_value = camera.maxHeight
	step = 1

func _process(delta):
	if !playerEntered:
		value = camera.translation.y
	else:
		camera.targetPos.y = value


func _on_VSlider_mouse_entered():
	# BUG TODO: When panning and mouse goes over the slider, rounding erros cause the camera to zoom in (make this also dependend on a real mouse click)
	playerEntered = true


func _on_VSlider_mouse_exited():
	# BUG TODO: When panning and mouse goes over the slider, rounding erros cause the camera to zoom in (make this also dependend on a real mouse click)
	playerEntered = false
