extends Spatial

###
"""
Access the ocean and get the water height on this current spatial position. 
Can emitt particles when velocity is high.
changes with a certain reactionSpeed.

"""

export var vel_threshold = 0.15
export(bool) var isOn = true
export(bool) var doParticles = true
var last_pos
export var reactionSpeed  = 0.01

var ocean
# Called when the node enters the scene tree for the first time.
func _ready():
	ocean = get_tree().get_nodes_in_group("Ocean")[0]
	last_pos = global_transform.origin.y



func _physics_process(delta):
	# if isOn:
	# 	global_transform.origin.y += (ocean.getWaterHeight(translation) - global_transform.origin.y)*reactionSpeed

	var vel = (global_transform.origin.y - last_pos)/delta
	last_pos = global_transform.origin.y
	if doParticles:
		if vel>vel_threshold:
			$Particles.emitting = true
			# print(vel)
		else:
			pass
			$Particles.emitting = false
