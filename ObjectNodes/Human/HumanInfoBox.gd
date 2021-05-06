extends TextureRect

var positionRef # ref to the positioner in the UI, used for position
var currentHealth
var itemLabel 
var isActive = true
var statusLabel
var myHuman
var healthLabel



func _ready():
	## fetch buttons and labels and other UI stuff
	itemLabel = $Panel/ItemLabel
	statusLabel = $Panel/StatusLabel
	healthLabel = $Panel/HealthLabel
	pass

func link(itemRef):
	"""
	Links this info box to the clicked item. Sets this states to the items vars.
	"""
	myHuman = itemRef
	$Panel/Title.text = str(myHuman.id)

	# statusLabel.pressed = myHuman.isActive
	pass
	
func _process(delta):
	# if myHuman.targetItem!=null:
	# 	if myHuman.targetItem.name!=null:
	# 		itemLabel.text = str(myHuman.targetItem.name)
	# else:
	# 	itemLabel.text = "null"

	# statusLabel.text = str(myHuman.isAssigned)

	if is_instance_valid(positionRef):
		self.rect_position =  positionRef.rect_position
		# center position
		self.rect_position.x -=  132 # half the width of panel
		self.rect_position.y -=  220 # height of info panel


# func _on_ActiveToggle_toggled(button_pressed):
# 	isActive = button_pressed
# 	myHuman.isActive = isActive
