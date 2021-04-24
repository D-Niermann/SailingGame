extends Node

var ID = 1000

func _ready():
	pass


func getID():
	""" returns a unique integer """
	ID += 1
	return ID