extends Node

"""
AutoLoaded
Here, the player inputs get decided. All Items and the Ship and UI stuff should access vars from here to decide what to do.
"""

var sailStep = 0.02
var rudderStep = 0.007

var playerAimCannons : bool  = false # true while player is aiming cannons
var rudderPos = 0 # -1,1 : -1 == left max, 1 == right max
var sailsTarget = 0 # 1 == max , how far out the sails should be
var turnCommandPressed  = false

var leftClick: bool = false
var rightClick: bool = false

signal onFireCannons # emitted when player firing cannons
signal playerFireTest # emitted when test fire 



func _ready():
	pass 
	## register to object references
	# GlobalObjectReferencer.inputManager = self


# Catches only the input which has not been handled yet.
func _unhandled_input(event):
	if event.is_action_pressed("leftClick") && !event.is_echo():
		leftClick = true
	if event.is_action_pressed("rightClick") && !event.is_echo():
		rightClick = true

	## if shop is closed
	if GlobalObjectReferencer.shopping.open == null:
		## cannon stuff
		if event.is_action_pressed("FireCannons"):
			playerAimCannons = true
		if event.is_action_released("FireCannons"):
			playerAimCannons = false
			emit_signal("onFireCannons")
		if event.is_action_released("testFire") and playerAimCannons:
			emit_signal("playerFireTest")

		## ship control
		if Input.is_action_pressed("turnLeft"):
			turnCommandPressed = true
			if rudderPos > -1:
				rudderPos -= rudderStep
		if Input.is_action_pressed("turnRight"):
			turnCommandPressed = true
			if rudderPos < 1:
				rudderPos += rudderStep
		if Input.is_action_just_released("turnLeft"):
			turnCommandPressed = false
		if Input.is_action_just_released("turnRight"):
			turnCommandPressed = false


		if Input.is_action_pressed("sailsUp"):
			if sailsTarget<1:
				sailsTarget	 += sailStep
		if Input.is_action_pressed("sailsDown"):
			if sailsTarget > 0:
				sailsTarget	 -= sailStep
		


func _process(delta):
	reset()
	 


# Resets all inputs to their base value.
func reset():
	leftClick = false
	rightClick = false
	if not turnCommandPressed:
		rudderPos *= 0.99

