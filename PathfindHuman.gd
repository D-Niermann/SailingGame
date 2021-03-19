extends Spatial


# Declare member variables here. Examples:
# var a = 2
# var b = "text"
onready var nav = get_parent()
onready var rigid = get_node("RigidBody")
var path = []
export var path_node = 0
var target_pos
var dir

onready var target = get_node("../NavMesh/Target")
export var speed = 0.015

# Called when the node enters the scene tree for the first time.
func _ready():
	target_pos = target.transform.origin
	path_node = 0
	var a = nav.get_closest_point(self.transform.origin)
	self.transform.origin = a
	pass # Replace with function body.

func _physics_process(delta):
#	print(path_node)
	if target_pos != target.transform.origin:
		target_pos = target.transform.origin
		path_node = 0
		path = nav.get_simple_path(self.transform.origin, target_pos)
	if path_node<path.size():
		dir = path[path_node] - self.transform.origin
		
		if dir.length()<0.01:
			path_node+=1
		else:
			## move human
#			rigid.add_force(dir, Vector3(0,0,0))
			self.transform.origin += dir.normalized()*speed
	elif path_node == path.size():
		pass
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
#	print(nav)
#	print(nav.get_simple_path(self.transform.origin, Vector3(10,0,0)))

	
#	print(path)
