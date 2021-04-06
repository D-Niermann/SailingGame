extends KinematicBody


# Declare member variables here. Examples:
# var a = 2
# var b = "text"
var velocity = 6 
var dir = Vector3(-1,0,0)
var default_gravity = 5
var gravity = default_gravity
var gravity_dir = Vector3(0,-1,0)
var water_gravity = default_gravity/4 # gravity force when underwater
# var start_impulse = 10
var default_drag_factor = 0.99 # [0,1] higher number = less drag!
var water_drag = 0.85 # [0,1] higher number = less drag!
var drag_factor = default_drag_factor
var entered
var time
var bullet_resistance = 0
var vel_penetrate_thresh = 0.0 # the velocity needs to be bigger than this to even consider penetration
var ricochet_thresh = 60 # TODO: make this also dependend on coll object # in degree. lower number means more ricochet, thus less penetration TODO: could be assigned from other object
var angle
var isInsideBody = false
var last_pos = translation
var coll_obj
var drag = 0
var grav_time
var isMarkedasDestruct : bool = false
## old ball stuff
var timeout_s = 10
var water
var waterEntered = false
var ocean
# Called when the node enters the scene tree for the first time.
func _ready():
	time = 0
	grav_time = 0
	$Trail.emitting = true
	if get_tree().get_nodes_in_group("Ocean").size()>0: ## TODO: ocean get water height could put into Utils script?
		ocean = get_tree().get_nodes_in_group("Ocean")[0]
	# last_pos.push_back(translation)
	# apply_impulse(transform.origin,Vector3(1,0,0)*-15)
	pass # Replace with function body.

func checkAndDestroy():
	if !isMarkedasDestruct:
		if global_transform.origin.y<-1000 or time>timeout_s or (!waterEntered and abs(velocity)<0.0001):
			isMarkedasDestruct = true
			yield(get_tree().create_timer(1),"timeout")
			self.queue_free()


func _process(delta):
	if isMarkedasDestruct:
		$Mesh.get_surface_material(0).albedo_color.a -= 1/60.0
	time += delta
	grav_time += delta
	var waterHeight = 0
	checkAndDestroy()
	if ocean!= null:
		waterHeight = ocean.getWaterHeight(global_transform.origin)
	if  waterHeight > transform.origin.y:
		drag_factor = 0.1
		if not waterEntered:
			default_drag_factor = water_drag
			# default_gravity = water_gravity ## TODO: lets bullets shoot a bit up when hitting water, why?
			waterEntered = true
			$Trail.emitting = false
			$WaterSplash.emitting = true
			$WaterSplash2.emitting = true
	## check collisions and move the object 
	var coll = move_and_collide(dir*velocity, false,false,true)
	# var coll2 = move_and_collide(gravity_dir*gravity*delta, false,false,true)
	# print(coll)

	## vertical move
	if velocity>vel_penetrate_thresh:
		translate(dir*velocity)
	else:
		move_and_slide(dir*velocity)
	if not isInsideBody:
		## gravity move
		move_and_slide(gravity_dir*gravity*grav_time*pow(drag_factor,1)) # todo why power here?
	if velocity<0.1:
		$Trail.emitting = false
		# if coll2!=null:
		# 	time = 0
	
	### calcualte direction after translation
	# dir = (translation - last_pos).normalized()
	# dir += (dir*velocity + gravity_dir*gravity).normalized()
	# velocity = (dir*velocity + gravity_dir*gravity).length()*drag_factor

	if coll!=null:
		grav_time = 0
		## if collision with object
		if not isInsideBody:
			angle = abs(coll.normal.normalized().angle_to(translation-last_pos)*180/PI-180)
			# print(angle)
			if angle>ricochet_thresh and velocity>vel_penetrate_thresh:
				## redirect ball
				dir = dir.bounce(coll.normal.normalized())
				## lose velocity based on angle
				velocity *= (angle/90)*0.5 ## 0.5 => energy loss through heat and stuff
			else:
				## if inside body:
				coll_obj = instance_from_id(coll.collider_id)
				if not coll_obj.get("drag") == null:
					drag_factor = coll_obj.drag
				else:
					drag_factor = 0.5
				if coll_obj.has_method("giveDmg"):
					coll_obj.giveDmg((translation-last_pos).length()) ##give damage to object
				gravity = 0
				playAudio()
				isInsideBody = true
	else:
		## if no collision with object
		isInsideBody = false
		drag_factor = default_drag_factor
		gravity = default_gravity

	velocity *= drag_factor

	## resets
	last_pos = translation

	
func playAudio():
	var sound = $Audio
	sound.set_pitch_scale(sound.pitch_scale+rand_range(-0.2,0.2))
	sound.play()