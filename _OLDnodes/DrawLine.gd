tool
extends ImmediateGeometry

func _ready():
	pass

func _process(delta):
	self.clear()
	self.begin(PrimitiveMesh.PRIMITIVE_LINES)
	self.set_color(Color(1,1,1))
	self.add_vertex(Vector3(0, 50,0)) 
	self.add_vertex(Vector3(0, 50,0) + Vector3(0,-100,0))	
	self.end()
