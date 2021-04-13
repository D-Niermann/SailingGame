extends DirectionalLight


# Declare member variables here. Examples:
var time = 0
onready var start_transform = self.transform


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	time+=delta
	
