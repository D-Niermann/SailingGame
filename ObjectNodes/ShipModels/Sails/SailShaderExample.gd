extends Spatial

var rand_time_offset = 0.0
var calledLateReady = false
var myShip = null

func _ready():
	rand_time_offset = rand_range(0,2) # if max rand number is around PI, the difference in the shaders is not that big, set to inf and diff is also maximum possible
	$Sail.material_override.set_shader_param("time_offset", rand_time_offset)

func _process(delta):
	if not calledLateReady:
		lateReady()
		calledLateReady = true
	$Sail.material_override.set_shader_param("sail_in", 1-myShip.sails)
	

func lateReady():
	## register to player item
	myShip = GlobalObjectReferencer.playerShip
