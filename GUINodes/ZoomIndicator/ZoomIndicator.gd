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
	playerEntered = true


func _on_VSlider_mouse_exited():
	playerEntered = false
