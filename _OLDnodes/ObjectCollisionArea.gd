extends Area


# Declare member variables here. Examples:
# var a = 2
# var b = "text"
# export var bullet_resistance = 0.01


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func _on_Area_body_entered(a):
	print(a.linear_velocity)
# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
