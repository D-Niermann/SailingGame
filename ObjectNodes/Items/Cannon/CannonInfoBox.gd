extends TextureRect

var positionRef # ref to the positioner in the UI, used for position
var currentHealth
var healthLabel 
var isActive = true
var activeButton
var myItem



func _ready():
	## fetch buttons and labels and other UI stuff
	healthLabel = $Panel/HealthLabel
	activeButton = $Panel/ActiveToggle

func link(itemRef):
	"""
	Links this info box to the clicked item. Sets this states to the items vars.
	"""
	myItem = itemRef
	$Panel/Title.text = myItem.name
	activeButton.pressed = myItem.isActive
	
func _process(delta):
	healthLabel.text = str(round(myItem.currentHealth))
	if positionRef!=null:
		self.rect_position =  positionRef.rect_position


func _on_ActiveToggle_toggled(button_pressed):
	isActive = button_pressed
	myItem.isActive = isActive
