extends Spatial

export var xRange = [0,0] # user input for the range in wich the deck is, this is an integer list because range() only supports integer
export var yRange = [0,0] # user input for the range in wich the deck is, this is an integer list because range() only supports integer
var collChecker 
var ix = 0
var xyArray = []
var positionSprites : Dictionary = {}
var positionOccupated : Dictionary = {}
const FREE = Color(0.0,0.0,0.0)
const BLOCKED = Color(0.7,0.2,0.0)


 
func _ready():
	pass
