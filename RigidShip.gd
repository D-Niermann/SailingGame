extends RigidBody


# Declare member variables here. Examples:
# var a = 2
# var b = "text"
var impulse_factor = 5

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func _physics_process(delta):
	var boye = $Spatial
	if translation.y<1:
		apply_impulse(boye.transform.origin,Vector3(0,1,0)*1*impulse_factor*delta)
	# apply_central_impulse(Vector3(0,0,1*impulse_factor))
