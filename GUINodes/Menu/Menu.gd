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


func _on_Return_pressed():
	get_tree().paused = false
	var menu: ColorRect = get_node("Menu")
	menu.mouse_filter = Control.MOUSE_FILTER_IGNORE
	menu.visible = false
	get_node("MenuButton").visible = true


func _on_Options_pressed():
	pass # Replace with function body.


func _on_Exit_pressed():
	get_tree().paused = false
	var menu: ColorRect = get_node("Menu")
	menu.mouse_filter = Control.MOUSE_FILTER_IGNORE
	get_tree().change_scene("res://GUINodes/Menu/MainMenu.tscn")


func _on_MenuButton_pressed():
	get_tree().paused = true
	var menu: ColorRect = get_node("Menu")
	menu.mouse_filter = Control.MOUSE_FILTER_STOP
	menu.visible = true
	get_node("MenuButton").visible = false


func _on_Save_pressed():
	var terminal = get_tree().get_root().get_node("GameWorld")
	terminal.saveGame(Utility.lastSlot)
