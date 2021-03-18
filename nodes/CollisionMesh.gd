extends MeshInstance


# Declare member variables here. Examples:
# var a = 2
# var b = "text"
var mdt = MeshDataTool.new()


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
	var mesh = self.mesh
	var a = self.create_trimesh_collision()
	
	
#	var vertex
#	mdt.create_from_surface(mesh, 0)
#	for i in range(mdt.get_vertex_count()):
#		vertex = mdt.get_vertex(i)
#
#	print(mesh.get_faces()[0])
