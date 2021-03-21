extends OmniLight


# Declare member variables here. Examples:
# var a = 2
# var b = "text"
var time = 0
var freq = 3
var amp = 0.1
var org_pos

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.
	org_pos = transform.origin


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	time += delta
	transform.origin = org_pos + Vector3(sin(time*freq*0.3565)*amp,0,cos(time*freq)*amp)
