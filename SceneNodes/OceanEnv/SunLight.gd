extends DirectionalLight

var threshold = 5
var lastheight = 0
func _ready():
	pass

func _process(delta):
	if is_instance_valid(GlobalObjectReferencer.camera):
		if abs(GlobalObjectReferencer.camera.transform.origin.y-lastheight) >= threshold:
			lastheight = GlobalObjectReferencer.camera.transform.origin.y
			directional_shadow_max_distance = lastheight+threshold
			print("set")
