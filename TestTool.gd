tool
extends Node


export var stringToHuman1 = ""
export var stringToHuman2 = ""
export var pathToC1 = ""
export var pathToC2 = ""
export var a = 0.0 
var h1;
var h2;
var c1;
var c2;
# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.
	h1 = get_node(stringToHuman1)
	h2 = get_node(stringToHuman2)
	c1 = get_node(pathToC1)
	c2 = get_node(pathToC2)
	print(c1)
	print(c2)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	a+=1
	# set_a(a)
	# print(h1.transform.origin)
	# print(c1.global_transform.basis.x.length())
	var c1Scale = c1.global_transform.basis.x.length()
	h1.transform.origin = c2.to_local(h2.global_transform.origin)/c1Scale
	# print("-----")
	pass

func _on_Body_mouse_entered(a):
	print("Mouse")
	
func _on_Body_body_entered(a):
	print("Entered")