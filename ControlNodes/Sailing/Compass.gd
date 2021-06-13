extends Control


var wheel: TextureRect
var barL: TextureProgress
var barR: TextureProgress
var arrow: TextureRect


# Called when the node enters the scene tree for the first time.
func _ready():
	wheel = $Control/Wheel
	barL = $Control/BarL
	barR = $Control/BarR
	arrow = $Control/Arrow


# Called every physics frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):
	#wheel.rect_rotation = InputManager.rudderPosition
	#arrow.rect_rotation = InputManager.sailsTarget
	barL.value = GlobalObjectReferencer.playerShip.sails
	barR.value = 0
