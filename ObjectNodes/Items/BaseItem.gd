extends KinematicBody

"""
All Items shall inherit from this script.
Here also all children instances can be stored, so that other script can acces the correct stuff from here. 
EG dont use $Mesh1 in some script but define mesh var here and access this var.
"""

export(float) var penetrationFactor = 2
var gridMesh

func _ready():
	gridMesh = get_node("GridShowMesh")
	pass # Replace with function body.

func on_placement():
	"""
	Gets called every time the item is placed onto the ship (shopping, replacing).
	"""
	if gridMesh!=null:
		gridMesh.visible = false # make the grid item invisible again
