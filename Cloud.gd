tool
extends Sprite3D


# Declare member variables here. Examples:
# var a = 2
# var b = "text"
var time
var rand
var start_opacity

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.
	rand = rand_range(-1,1)
	time = 0
	start_opacity = rand_range(0,1)
	print(rand)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	time += delta
	global_rotate(Vector3(0,1,0),0.0002*rand)
	opacity = start_opacity #-clamp(sin(time*0.005),0,1)