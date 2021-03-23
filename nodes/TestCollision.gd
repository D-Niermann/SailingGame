extends RigidBody


# Declare member variables here. Examples:
# var a = 2
# var b = "text"
var entered
var bullet_resistance = 0
# Called when the node enters the scene tree for the first time.
func _ready():
	apply_impulse(transform.origin,Vector3(1,0,0)*-15)
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	# translate(Vector3(0,-0.01,0))
	# if entered:
		# print(bullet_resistance)
		# apply_central_impulse(-self.linear_velocity*bullet_resistance)
	if linear_velocity.length()<15:
		sleeping=true
	pass
