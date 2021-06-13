extends Control


var wheel: TextureRect
var barL: TextureProgress
var barR: TextureProgress
var windArrow: TextureRect
var sailArrow: TextureRect


# Called when the node enters the scene tree for the first time.
func _ready():
	wheel = $Control/Wheel
	barL = $Control/BarL
	barR = $Control/BarR
	windArrow = $Control/WindSpeedArrow
	sailArrow = $Control/SailArrow


# Called every physics frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):
	#wheel.rect_rotation = InputManager.rudderPosition
	#windArrow.rect_rotation = InputManager.sailsTarget
	barL.value = GlobalObjectReferencer.playerShip.sails
	barR.value = GlobalObjectReferencer.playerShip.speed
	sailArrow.rect_rotation += ((-60+60*2*InputManager.sailsTarget)-sailArrow.rect_rotation)*0.1
	wheel.rect_rotation += (170*InputManager.rudderPos-wheel.rect_rotation)*0.03