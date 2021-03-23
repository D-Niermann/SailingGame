extends RigidBody


# Declare member variables here. Examples:
# var a = 2
# var b = "text"
var time;
var timeout_s = 10
var water
var waterEntered = false


# Called when the node enters the scene tree for the first time.
func _ready():
	time = 0
	water = $WaterHeight
	pass # Replace with function body.

# func _on_body_entered(body):
# 	print("Inside",body)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	time += delta
	if global_transform.origin.y<-1000 or time>timeout_s:
		self.queue_free()
	if water.global_transform.origin.y>transform.origin.y:
		if not waterEntered:
			waterEntered = true
			$Particles.emitting = true
		var f = 0.01
		self.apply_central_impulse(Vector3(-f*linear_velocity.x,0.00003*pow(Vector2(linear_velocity.x,linear_velocity.z).length(),2),-f*linear_velocity.z))


func _on_Ball_body_entered(body):
	pass # Replace with function body.
	print("test")
