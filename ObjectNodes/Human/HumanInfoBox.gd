extends TextureRect

var positionRef # ref to the positioner in the UI, used for position
var currentHealth
var itemLabel 
var isActive = true
var statusLabel
var myHuman
var healthLabel
var foodSlider


func _ready():
	## fetch buttons and labels and other UI stuff
	itemLabel = $Panel/ItemLabel
	statusLabel = $Panel/StatusLabel
	healthLabel = $Panel/HealthLabel
	foodSlider = $Panel/FoodSlider

func link(itemRef):
	"""
	Links this info box to the clicked item. Sets this states to the items vars.
	"""
	myHuman = itemRef
	$Panel/Title.text = str(myHuman.id)
	foodSlider.value = myHuman.stamina
	# statusLabel.pressed = myHuman.isActive
	
	
func _process(delta):
	# if myHuman.targetItem!=null:
	# 	if myHuman.targetItem.name!=null:
	# 		itemLabel.text = str(myHuman.targetItem.name)
	# else:
	# 	itemLabel.text = "null"

	# statusLabel.text = str(myHuman.isAssigned)
	
	foodSlider.value = myHuman.stamina
	if myHuman.currentTask!=null and myHuman.currentTask.type == "taskType:job":
		$Panel/ItemLabel.text = myHuman.currentTask.taskGroup + " | "  + str(myHuman.currentTask.priority) + " | " + GlobalObjectReferencer.crewManager.items[myHuman.currentTask.itemID].itemRef.databaseName
	elif myHuman.currentTask!=null and myHuman.currentTask.type == "taskType:fetch":
		$Panel/ItemLabel.text = myHuman.currentTask.taskGroup + " | " + str(myHuman.currentTask.priority) 
	else:
		$Panel/ItemLabel.text = ""
	if is_instance_valid(positionRef):
		self.rect_position =  positionRef.rect_position


# func _on_ActiveToggle_toggled(button_pressed):
# 	isActive = button_pressed
# 	myHuman.isActive = isActive
