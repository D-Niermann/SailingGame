extends Spatial


# Declare member variables here. Examples:
# var a = 2
# var b = "text"
var humans;

# Called when the node enters the scene tree for the first time.
func _ready():
	humans = get_tree().get_nodes_in_group("Human")


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	for i in humans:
#		print(i)

func _physics_process(delta):
	var space_state = get_world().direct_space_state
	# use global coordinates, not local to node
	var camera = get_node("../Camera")
	
	var result = space_state.intersect_ray(camera.transform.origin, Vector3(0, -1000,0))
#	print(result)
