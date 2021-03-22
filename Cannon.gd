extends Spatial


# Declare member variables here. Examples:
# var a = 2
# var b = "text"
# var ball
var forward
var up
var force = 10


# Called when the node enters the scene tree for the first time.
func _ready():
	# ball = $Ball
	# print(ball)
	set_process_input(true) 
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
	up = global_transform.basis.y.normalized()
	forward = global_transform.basis.x.normalized()
	# print(ball.linear_velocity)

func _input(event):
	# Receives key input
	if event.is_action_released("FireCannons"):
		var scene = load("res://nodes/Ball.tscn")
		print(scene)
		var ball = scene.instance()
		get_tree().get_root().add_child(ball)
		ball.set_name("Ball")
		ball.transform.origin = self.global_transform.origin
		ball.apply_impulse(ball.transform.origin,forward*force)

	# if Input.is_key_pressed(KEY_R):
	# 	self.add_child(ball)
	# 	ball.linear_velocity = Vector3(0,0,0)
	# 	ball.transform.origin = transform.origin

