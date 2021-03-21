extends OmniLight


# Declare member variables here. Examples:
# var a = 2
# var b = "text"
var time = 0+rand_range(0,1)
var freq = 3
var amp = 0.1
var org_pos
var org_energy

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.
	org_pos = transform.origin
	org_energy = self.light_energy


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	time += delta
	self.light_energy = org_energy+0.4*sin(3*time)*cos(4*time)
	transform.origin = org_pos + Vector3(sin(time*freq*0.3565)*amp,0,cos(time*freq)*amp)
