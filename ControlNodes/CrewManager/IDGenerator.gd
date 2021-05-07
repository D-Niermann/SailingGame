extends Node

var ID : int = 1000

func _ready():
	pass


func getID():
	""" returns a unique integer """
	ID += 1
	return ID