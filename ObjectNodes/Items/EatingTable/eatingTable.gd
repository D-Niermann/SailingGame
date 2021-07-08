extends "res://ObjectNodes/Items/BaseItem.gd"

func _ready():
	pass


func _process(delta):
	if GlobalObjectReferencer.crewManager.getInventoryCount(self.id, "Apples")>3:
		$Sprite3D.visible = false
		$FullTable.visible = true
	else:
		$Sprite3D.visible = true
		$FullTable.visible = false

