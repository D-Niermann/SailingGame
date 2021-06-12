extends Control


var food: Label
var ammo: Label
var powder: Label
var materials: Label


# Called when the node enters the scene tree for the first time.
func _ready():
	food = $Control/Food/Label
	ammo = $Control/Ammo/Label
	powder = $Control/Powder/Label
	materials = $Control/Materials/Label


# Called every physics frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):
	food.text = str(GlobalObjectReferencer.crewManager.getGroupAmount(Economy.IG_FOOD)) + "/" + str(GlobalObjectReferencer.crewManager.getCapacity(Economy.IG_FOOD))
	ammo.text = str(GlobalObjectReferencer.crewManager.getGroupAmount(Economy.IG_AMMO)) + "/" + str(GlobalObjectReferencer.crewManager.getCapacity(Economy.IG_AMMO))
	powder.text = str(GlobalObjectReferencer.crewManager.getGroupAmount(Economy.IG_GUNPOWDER)) + "/" + str(GlobalObjectReferencer.crewManager.getCapacity(Economy.IG_GUNPOWDER))
	materials.text = str(GlobalObjectReferencer.crewManager.getGroupAmount(Economy.IG_UTILITY)) + "/" + str(GlobalObjectReferencer.crewManager.getCapacity(Economy.IG_UTILITY))
