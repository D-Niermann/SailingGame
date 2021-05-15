extends TextureRect

var healthLabel
var gp_amount
var myItem
var positionRef

func _ready():
	## fetch buttons and labels and other UI stuff
	healthLabel = $Panel/HealthLabel
	gp_amount = $Panel/GPAmount

func link(itemRef):
	"""
	Links this info box to the clicked item. Sets this states to the items vars.
	"""
	myItem = itemRef
	# $Panel/Title.text = myItem.name
	
func _process(delta):
	healthLabel.text = str(round(myItem.currentHealth))
	gp_amount.text = str((GlobalObjectReferencer.crewManager.itemAssignmentsAndInventory[Economy.IG_GUNPOWDER][myItem.id].inventory["Gunpowder"]))
	if positionRef!=null:
		self.rect_position =  positionRef.rect_position
