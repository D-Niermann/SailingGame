extends Node


var aiming: bool = false
var firing: bool = false

var leftClick: bool = false
var rightClick: bool = false


# Catches only the input which has not been handled yet.
func _unhandled_input(event):
	if event.is_action_pressed("leftClick") && !event.is_echo():
		leftClick = true
	if event.is_action_pressed("rightClick") && !event.is_echo():
		rightClick = true


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	firing = false
	var mayFire = false
	if aiming:
		mayFire = true
	if GlobalObjectReferencer.shopping.open != null:
		aiming = false
	elif Input.is_action_pressed("rightClick"):
		aiming = true
	else:
		aiming = false
	if mayFire && !aiming:
		firing = true
	reset()


# Resets all inputs to false.
func reset():
	leftClick = false
	rightClick = false
