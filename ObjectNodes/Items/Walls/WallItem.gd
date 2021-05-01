extends "res://ObjectNodes/Items/BaseItem.gd"


var infoPanel

func _ready():
	fetchDictParams("WallLong")


func createInfo(placeholder):
	"""
	Instances the correponding item info panel and moves it to placeholder.rect_position.
	The instanced info box connects to this item and communicates user input and item stati.
	"""
	if InfoPanel!=null:
		## instance panel
		infoPanel = InfoPanel.instance()
		infoPanel.visible = false
		infoPanel.positionRef = placeholder
		self.add_child(infoPanel)
		infoPanel.rect_position = placeholder.rect_position

		## link self to panel, enables info access
		infoPanel.link(self)

		## make panel visible
		infoPanel.visible = true

func removeInfo():
	"""
	removes info panel again
	"""
	if infoPanel!=null:
		infoPanel.queue_free()

