extends KinematicBody

"""
All Items shall inherit from this script.
Here also all children instances can be stored, so that other script can acces the correct stuff from here. 
EG dont use $Mesh1 in some script but define mesh var here and access this var.
"""


export(bool) var movable = true
export(float) var penetrationFactor = 2 # penetration factor used for bullets
export(float) var maxHealth = 100

var gridMesh # green/red mesh that displays the hitbox of items
var itemPlaceParticle # dynamically loaded particles 
var currentHealth = maxHealth


func _ready():
	gridMesh = get_node("GridShowMesh")
	
	var particleRes = load("res://ObjectNodes/Items/ItemPlaceParticle.tscn")
	itemPlaceParticle = particleRes.instance()
	itemPlaceParticle.one_shot = true
	itemPlaceParticle.emitting = false
	add_child(itemPlaceParticle)

func on_placement():
	"""
	Gets called every time the item is placed onto the ship (shopping, replacing).
	"""
	if gridMesh!=null:
		gridMesh.visible = false # make the grid item invisible again
	itemPlaceParticle.emitting = true
	
