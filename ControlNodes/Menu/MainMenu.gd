extends Control


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass


func _on_Slot_pressed(slot):
	Utility.lastSlot = slot
	get_tree().change_scene("res://SceneNodes/GameWorld.tscn")


func _on_Continue_pressed():
	var temp = get_tree().get_root().get_node("MainMenu/Interface/Continue")
	var cont = temp.get_node("Container")
	for child in cont.get_children():
		child.queue_free()
	var slots = Utility.getSlots()
	for slot in slots.keys():
		var unix = slots[slot]["unix"]
		var button: TextureButton = TextureButton.new()
		button.rect_min_size = Vector2(300, 300)
		var file: File = File.new()
		if file.file_exists("user://" + slot + ".png"):
			var image: Image = Image.new()
			image.load("user://" + slot + ".png")
			var texture: ImageTexture = ImageTexture.new()
			texture.create_from_image(image)
			button.texture_normal = texture
		button.expand = true
		button.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_COVERED
		button.connect("pressed", self, "_on_Slot_pressed", [slot])
		var label: Label = Label.new()
		button.add_child(label)
		label.name = "Unix"
		label.text = str(unix)
		var placed: bool = false
		for child in cont.get_children():
			if int(child.get_node("Unix").text) < unix:
				cont.add_child_below_node(child, button)
				cont.move_child(child, child.get_index() + 1)
				placed = true
				break
		if !placed:
			cont.add_child(button)


func _on_NewGame_pressed():
	Utility.lastSlot = null
	get_tree().change_scene("res://SceneNodes/GameWorld.tscn")


func _on_Options_pressed():
	pass # Replace with function body.


func _on_Credits_pressed():
	pass # Replace with function body.


func _on_QuitGame_pressed():
	get_tree().quit()
