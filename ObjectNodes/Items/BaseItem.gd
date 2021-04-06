extends KinematicBody

"""
All Items shall inherit from this script.
Here also all children instances can be stored, so that other script can acces the correct stuff from here. 
EG dont use $Mesh1 in some script but define mesh var here and access this var.
"""
export(float) var penetrationFactor = 2
# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func myfunc1():
	pass
# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
