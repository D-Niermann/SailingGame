extends KinematicBody


# Declare member variables here. Examples:
# var a = 2
# var b = "text"
var velocity # the velocity in horizontla direciton, used for move and slide commands
var dir = Vector3(0,0,0)
var default_gravity = 1.0
var gravity = default_gravity
export var camShakeMod = 2.5
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
var ricochet_thresh = 80 # TODO: make this also dependend on coll object # in degree. lower number means less ricochet, thus less penetration TODO: could be assigned from other object
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
var stopMove = false  # true if movement should stop (stuck inside some body)
var coll # the colliding object
var waterEntered = false
var ocean
var speed = 0 # the actual, measured speed
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
			yield(get_tree().create_timer(5),"timeout")
			self.queue_free()


func _process(delta):
	# if isMarkedasDestruct:
	# 	$Mesh.get_surface_material(0).albedo_color.a -= 1/60.0 # bug: looks shitty over water shader, and also affects all other balls materials
	time += delta
	grav_time += delta
	var waterHeight = 0
	checkAndDestroy()
	if ocean!= null:
		waterHeight = ocean.getWaterHeight(global_transform.origin)
	if  waterHeight > global_transform.origin.y:
		drag_factor = 0.1
		if not waterEntered:
			default_drag_factor = water_drag
			# default_gravity = water_gravity ## TODO: lets bullets shoot a bit up when hitting water, why?
			waterEntered = true
			$Trail.emitting = false
			$WaterSplash.emitting = true
			$WaterSplash2.emitting = true
	
	if !stopMove:
		## check collisions and move the object 
		coll = move_and_collide(dir*velocity, false,false,true)
		# var coll2 = move_and_collide(gravity_dir*gravity*delta, false,false,true)
		# print(coll)

		## vertical move
		if velocity>vel_penetrate_thresh:
			translate(dir*velocity)
		else:
			move_and_slide(dir*velocity)
		if not isInsideBody:
			## gravity move
			move_and_slide(gravity_dir*gravity*grav_time*drag_factor) 

	speed = (translation-last_pos).length()

	if speed<0.1:
		$Trail.emitting = false
	if speed<0.0001:
		if is_instance_valid(coll_obj) and !stopMove: # permanently stuck inside some body, add as child to obj to keep moving with it 
			var globalPos = global_transform.origin
			get_parent().remove_child(self)
			coll_obj.add_child(self)
			global_transform.origin = globalPos
			stopMove = true
	
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
				
				if not coll_obj.get("penetrationFactor") == null:
					drag_factor = coll_obj.penetrationFactor
				else:
					drag_factor = 0.5
				if coll_obj.has_method("giveDmg"):
					coll_obj.giveDmg(speed) ##give damage to object
				gravity = 0

				if speed>0.1:
					playAudio()
					GlobalObjectReferencer.camera.shake_val += speed * camShakeMod /clamp(GlobalObjectReferencer.camera.global_transform.origin.distance_to(global_transform.origin)*0.02,1,99999)	
					$HitParticle.emitting = true
					$HitParticle.get_child(0).emitting = true
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
	var sound = $HitSound
	sound.set_pitch_scale(sound.pitch_scale+rand_range(-0.3,1.0))
	sound.play()
