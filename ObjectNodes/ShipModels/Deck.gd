extends KinematicBody

"""
All decks must have this script. 
It stores the tiles on which items can be placed, this is also accessed via the pathfinding.
It requires a collision box which defines where items can be placed.
User needs to assign the dimensions of the deck in the editor.

TODO: onready check where tiles are: maybe mirror along the long axis of ship to guarantee symmetry
"""
export var Marker: PackedScene 
var markerManager 

var collider = null
var isTileOccupied = {} # dictionary of keys vec2 positions contains boolen if the current thing is occupied or not
var positionMarkers = {}

export var xRange = [0,0] # user input for the range in wich the deck is, this is an integer list because range() only supports integer
export var yRange = [0,0] # user input for the range in wich the deck is, this is an integer list because range() only supports integer
const C_FREE = Color(0.0,0.0,0.0)
const C_BLOCKED = Color(0.7,0.2,0.0)
const TILEWIDTH = 0.2


func _ready():

	collider = $CollChecker
	markerManager = $BuildMarkerManager

	var x
	var y
	for _x in range(xRange[0]*10,xRange[1]*10,2):
		for _y in range(yRange[0]*10,yRange[1]*10,2):
			x = TILEWIDTH/2.0+_x/10.0
			y = TILEWIDTH/2.0+_y/10.0
			collider.transform.origin = Vector3(x,0,y)
			var coll = collider.move_and_collide(Vector3(0.0,-0.0,0.0), true , true , true)
			if is_instance_valid(coll):
				var marker = Marker.instance()
				markerManager.add_child(marker)
				marker.set_name("Marker")
				marker.transform.origin = Vector3(x,0,y)
				isTileOccupied[Vector2(x,y)] = true
				positionMarkers[Vector2(x,y)] = marker
				marker.modulate = C_FREE
				var coll2 = collider.move_and_collide(Vector3(0.0,+0.1,0.0), true , true , true)
				if is_instance_valid(coll2):
					marker.modulate = C_BLOCKED
					isTileOccupied[Vector2(x,y)] = false

func _process(delta):
	if is_instance_valid(GlobalObjectReferencer.shopping):
		if GlobalObjectReferencer.shopping.open != null:
			## shop is open: 
			markerManager.visible = true
		else:
			markerManager.visible = false
	else:
		markerManager.visible = false


func checkIfFree(array)-> bool:
	"""
	given an array of vector2 positions, checks if all the tiles are free
	"""
	for pos in array:
		if isTileOccupied[pos]:
			return false
	return true

func occupyTiles(array):
	"""
	given an array of vector2 positions, occupies all these positions
	"""
	for pos in array:
		_occupyTile(pos)

func freeTiles(array):
	"""
	given an array of vector2 positions, occupies all these positions
	"""
	for pos in array:
		_freeTile(pos)

func _occupyTile(pos : Vector2):
	isTileOccupied[pos] = true
	positionMarkers[pos].modulate = C_BLOCKED

func _freeTile(pos : Vector2):
	isTileOccupied[pos] = false
	positionMarkers[pos].modulate = C_FREE
