extends Spatial


# Declare member variables here. Examples:
# var a = 2
# var b = "text"
var pos: Vector3 = Vector3(0,0,0)
var pos_old: Vector3 = pos
var pos_diff = 0 # up velocity of the pos
export var posParticleThresh = 0.3
var waterSplashParticles
# Called when the node enters the scene tree for the first time.
func _ready():
	waterSplashParticles = $WaterSplashParticles

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):
	pos = global_transform.origin*100
	pos_diff = (pos.y-pos_old.y)
	if pos_diff>posParticleThresh:
		waterSplashParticles.emitting = true
	else:
		waterSplashParticles.emitting = false
	pos_old = pos
