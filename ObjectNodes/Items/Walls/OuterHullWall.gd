extends "res://ObjectNodes/Items/BaseItem.gd"

var isLeaking = false 
var leakHealth = 5 #threshold under which leaking starts

func _ready():
	maxHealth = 10
	currentHealth = maxHealth


func _physics_process(delta):
	if isLeaking:
		myShip.fillWater(0.01*delta)

# overwrite base function for extra stuff
func giveDmg(damage : float):
	.giveDmg(damage) # call parent function
	## extras
	if currentHealth<leakHealth:
		isLeaking = true
		if $WaterLeakParticles!=null:
			$WaterLeakParticles.emitting = true
		if $WaterLeakParticles2!=null:
			$WaterLeakParticles2.emitting = true
		if $WaterLeakParticles3!=null:
			$WaterLeakParticles3.emitting = true
	
