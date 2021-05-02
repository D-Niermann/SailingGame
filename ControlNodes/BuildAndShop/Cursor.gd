extends Control


var viewport: Viewport
var selectedDeckNumber: int
var hit: Dictionary = {}
var selected = null
var info: Control = null

var leftClick: bool = false
var rightClick: bool = false
var scrollUp: bool = false
var scrollDown: bool = false

var shopper = null
var builder = null


# Called when the node enters the scene tree for the first time.
func _ready():
	GlobalObjectReferencer.cursor = self
	viewport = get_tree().get_root().get_node("GameWorld/ViewportContainer/Viewport")
	selectedDeckNumber = -1
	info = get_node("Info")


# Catches only the input which has not been handled yet.
func _unhandled_input(event):
	if event.is_action_pressed("leftClick") && !event.is_echo():
		leftClick = true
	if event.is_action_pressed("rightClick") && !event.is_echo():
		rightClick = true
	if event.is_action_released("rotateItemLeft"):
		scrollUp = true
	if event.is_action_released("rotateItemRight"):
		scrollDown = true


# Called every physics frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):
	scan() # raycasts to set the dictionary called hit
	# on leftclick, if shop is closed, if hit has info, open info box
	if GlobalObjectReferencer.shopping.open == null:
		if leftClick: # and not in shop or building
			if !hit.empty() && Economy.malls.has(hit.collider.name) && GlobalObjectReferencer.playerShip.linear_velocity.length_squared() < GlobalObjectReferencer.shopping.speedLimit && GlobalObjectReferencer.playerShip.global_transform.origin.distance_squared_to(Economy.malls[hit.collider.name]["loci"]) < GlobalObjectReferencer.shopping.distanceLimit: # opens shop, if hit's a shop
				GlobalObjectReferencer.shopping.openShop(hit.collider.name)
			if !hit.empty() && hit.collider.has_method("createInfo"):
				if is_instance_valid(selected):
					selected.removeInfo()
				selected = hit.collider
				info2(selected)
				selected.createInfo(info)
			elif is_instance_valid(selected):
				selected.removeInfo()
				selected = null
		if is_instance_valid(selected):
			info2(selected)
	elif is_instance_valid(selected):
		selected.removeInfo()
		selected = null
	resetInput()


# Resets input.
func resetInput():
	leftClick = false
	rightClick = false
	scrollUp = false
	scrollDown = false


# Raycasts on cursor to set lastHit.
func scan():
	var selectedDeck = null
	if selectedDeckNumber != -1:
		selectedDeck = get_tree().get_nodes_in_group("PlayerDeck")[selectedDeckNumber]
	var camera: Camera = viewport.get_camera()
	var spaceState: PhysicsDirectSpaceState = camera.get_world().direct_space_state
	var viewportContainer: ViewportContainer = viewport.get_parent()
	var cursor = get_viewport().get_mouse_position() / viewportContainer.stretch_shrink
	var toIgnore: Array = []
	if is_instance_valid(GlobalObjectReferencer.shopping.hologram):
		toIgnore.append(GlobalObjectReferencer.shopping.hologram)
	var from = camera.project_ray_origin(cursor)
	var toward = camera.project_ray_normal(cursor)
	hit = spaceState.intersect_ray(from, from + toward * 2000, toIgnore, 0b1)
	while !hit.empty() && selectedDeck != null && hit.collider != selectedDeck && hit.collider.get_parent() != selectedDeck && hit.collider.name != "HTerrain" && !Economy.malls.has(hit.collider.name):
		toIgnore.append(hit.collider)
		hit = spaceState.intersect_ray(from, from + toward * 2000, toIgnore, 0b1)
#	if !hit.empty():
#		print(hit.collider.name)


# Updates location of infobox to hover above the given thing.
func info2(thing):
	var camera: Camera = viewport.get_camera()
	var viewportContainer: ViewportContainer = viewport.get_parent()
	var pos: Vector2 = camera.unproject_position(selected.global_transform.origin)
	info.rect_position = Vector2(clamp(pos.x, 0, viewport.size.x), clamp(pos.y, 0, viewport.size.y)) * viewportContainer.stretch_shrink


# Changes the selected deck number to the given integer.
func selectDeck(deckNumber: int):
	selectedDeckNumber = deckNumber
