extends TextureRect

var healthLabel
var positionRef # ref to the positioner in the UI, used for position
var myItem

func _ready():
	healthLabel = $Panel/HealthLabel

func link(itemRef):
	"""
	Links this info box to the clicked item. Sets this states to the items vars.
	"""
	myItem = itemRef


func _process(delta):
	healthLabel.text = str(round(myItem.currentHealth))
	if positionRef!=null:
		self.rect_position =  positionRef.rect_position
	