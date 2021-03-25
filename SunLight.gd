extends DirectionalLight


# Declare member variables here. Examples:
var time = 10
onready var start_transform = self.transform


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	time+=delta*0.1
	self.transform = start_transform.rotated(Vector3(1,0,0), time)
