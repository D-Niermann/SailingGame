extends MeshInstance

var vtx
var n = 0
var mtool = MeshDataTool.new()
var camera
var value = 0
onready var myMesh
export(float) var ocean_height = 0.0

func _ready():
	camera = get_node("../../Camera")
	

	
## warning-ignore:unused_argument
#	self.create_convex_collision()
func _physics_process(delta):
	value += 1
	if value == 10:
		value = 0

		# move waterplane to camera
		transform.origin = camera.transform.origin

		# snapping the waterplane to world grid to avoid wobbling
#		transform.origin.x = round(transform.origin.x / 2.0) * 2.0 # 4.0 = 4 meter grid
#		transform.origin.z = round(transform.origin.z / 2.0) * 2.0
		transform.origin.y = ocean_height # waterheight
