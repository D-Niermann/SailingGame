extends TextureRect

var positionRef # ref to the positioner in the UI, used for position
var currentHealth
var healthLabel 
var crewRatingLabel
var myItem



func _ready():
	## fetch buttons and labels and other UI stuff
	healthLabel = $Panel/HealthLabel
	crewRatingLabel = $Panel/CrewRating
	# activeButton = $Panel/ActiveToggle
	# activeButton = $Panel/IsTestCannon

func link(itemRef):
	"""
	Links this info box to the clicked item. Sets this states to the items vars.
	"""
	myItem = itemRef
	$Panel/Title.text = myItem.databaseName
	$Panel/ActiveToggle.pressed = myItem.isActive
	$Panel/IsTestCannon.pressed = myItem.isTestCannon
	$Panel/DelaySlider.value = myItem.fire_delay_sec
	$Panel/DelaySlider/SliderVal.text = ( str($Panel/DelaySlider.value) + "s")
	
	
func _process(delta):
	healthLabel.text = str(round(myItem.currentHealth))
	crewRatingLabel.text = str(round(3*GlobalObjectReferencer.crewManager.items[myItem.id].crewScore))+"/3"
	$Panel/GunpowderCount.text = str(GlobalObjectReferencer.crewManager.getInventoryCount(myItem.id, "Gunpowder"))
	$Panel/BallsCount.text = str(GlobalObjectReferencer.crewManager.getInventoryCount(myItem.id, "Cannonballs"))
	if is_instance_valid(positionRef):
		self.rect_position =  positionRef.rect_position
		self.rect_position.x -=  100 # half the width of panel
		self.rect_position.y -=  250 # height of info panel


func _on_ActiveToggle_toggled(button_pressed):
	myItem.isActive = button_pressed


func _on_isTestCannon_toggled(button_pressed):
	myItem.isTestCannon = button_pressed


func _on_HSlider_value_changed(value):
	myItem.fire_delay_sec = $Panel/DelaySlider.value
	$Panel/DelaySlider/SliderVal.text = ( str($Panel/DelaySlider.value) + "s")
