extends StaticBody


func _ready():
	pass


func onHover(isHover:bool):
	if isHover:
		$Sprite.modulate = Color(1.0,1.0,0.5,1.0)
	else:
		$Sprite.modulate = Color(1.0,1.0,1.0,1.0)
