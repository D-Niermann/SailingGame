extends "res://ObjectNodes/Items/BaseItem.gd"

var infoPanel

func _ready():
	pass
	
func createInfo(placeholder):
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
	if infoPanel!=null:
		infoPanel.queue_free()
	
