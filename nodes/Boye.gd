extends Spatial

###
"""
Rewrtie this so that only the ship manager needs to load
the resource (or something else global) and then this here
only transforms the coordinate
"""



###
# Declare member variables here. Examples:
# var a = 2
# var b = "text"
export var doPrint = 0
export var vel_threshold = 0.22
export var run = 1
var last_pos
var camera
var pixel
var image
var data
var targetPos1
var targetPos2
var h_target
var h1
var h2
var reactionSpeed  = 0.03
var px_x1
var px_y1
var px_x2
var px_y2
var time
var time_b = 0
var time_offset = 0
var imSize = 1024.0 # size in px of the height map
var gerstner_tiling1 = imSize/40.0
var gerstner_tiling2 = imSize/200.0
var gerstner_height1 = 1
var gerstner_height2 = 4
var gerstner_speed1 = Vector2(0, 0)#Vector2(8, 4)
var gerstner_speed2 = Vector2(0, 0)#Vector2(8, 4)
# Called when the node enters the scene tree for the first time.
func _ready():
	image = load("res://gerstner_height.jpg")
	# camera = get_tree().get_nodes_in_group("Camera")[0]
	data = image.get_data()
	time = 0
	last_pos = global_transform.origin.y

	

func _input(event):
	if event is InputEventKey and event.pressed:
		if event.scancode == KEY_F:
			time_offset = time
			gerstner_speed1 = Vector2(0.05*imSize,0.05*imSize) ## 5 times faster since img / tiling is 5 times smaller
			gerstner_speed2 = Vector2(0.025*imSize,0.025*imSize)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
	data.lock()
	time += delta
	if run:
		# transform.origin.x = camera.transform.origin.x + 3
		# transform.origin.z = camera.transform.origin.z + 3
		## i think for negative values the pos needs to be flipped somehow
		targetPos1 = self.global_transform.origin*gerstner_tiling1
		targetPos2 = self.global_transform.origin*gerstner_tiling2
		# h1 = gerstner_height1 * data.get_pixel(fmod(targetPos1.x,imSize), fmod(targetPos1.z,imSize))[0]

		## pixel 1
		px_x1 = fmod(targetPos1.x+gerstner_speed1.x*(time-time_offset),imSize)
		px_y1 = fmod(targetPos1.z+gerstner_speed1.y*(time-time_offset),imSize)
		if px_x1<0:
			px_x1 = abs(abs(px_x1)-imSize)
		if px_y1<0:
			px_y1 = abs(abs(px_y1)-imSize)

		## pixel 2
		px_x2 = fmod(targetPos2.x+gerstner_speed2.x*(time-time_offset),imSize)
		px_y2 = fmod(targetPos2.z+gerstner_speed2.y*(time-time_offset),imSize)
		if px_x2<0:
			px_x2 = abs(abs(px_x2)-imSize)
		if px_y2<0:
			px_y2 = abs(abs(px_y2)-imSize)

		h1 = gerstner_height1 * data.get_pixel(px_x1, px_y1)[0]
		h2 = gerstner_height2 * pow(data.get_pixel(px_x2, px_y2)[0],0.5)
		h_target = h1 + h2
		## power 
		# h2 = pow(h2, 0.4545)
		global_transform.origin.y += (h_target - global_transform.origin.y)*reactionSpeed
	data.unlock()

	# if round(time)!= time_b:
	# 	print(transform.origin)
	# 	print(px_x2, " | ", px_y2)
	# 	print(h2)
	# 	print("---------")
	# 	time_b = round(time)
	
func _physics_process(delta):
	var vel = (global_transform.origin.y - last_pos)/delta
	last_pos = global_transform.origin.y
	if doPrint==1:
		if vel>vel_threshold:
			$Particles.emitting = true
			print(vel)
		else:
			pass
			$Particles.emitting = false
