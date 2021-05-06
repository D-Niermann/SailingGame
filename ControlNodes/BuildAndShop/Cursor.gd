extends Control


const SELECT: Texture = preload("res://ControlNodes/Images/cursor.png")
const ATTACK: Texture = preload("res://ControlNodes/Images/attackCursor.png")
const BUILD: Texture = preload("res://ControlNodes/Images/shoppingCursor.png")

var viewport: Viewport
var selectedDeckNumber: int
var hit: Dictionary = {}
var selected = null
var hovering = null
var info: Control = null
var size: Vector2 = Vector2.ZERO

var leftClick: bool = false
var rightClick: bool = false
var scrollUp: bool = false
var scrollDown: bool = false


# Called when the node enters the scene tree for the first time.
func _ready():
	viewport = get_tree().get_root().get_node("GameWorld/ViewportContainer/Viewport")
	var size: Vector2 = OS.get_screen_size()
	scaleCursor(size)
	GlobalObjectReferencer.cursor = self
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
	# scaling cursor if screen size is changed
	var tempSize: Vector2 = OS.get_screen_size()
	if size != tempSize:
		size = tempSize
		scaleCursor(size)
	scan() # raycasts to set the dictionary called hit
	var newHovering = null # to change highlighted objects
	if !hit.empty() && hit.collider.has_method("onHover"):
		newHovering = hit.collider
	if hit.empty():
		Input.set_default_cursor_shape(0)
	elif Economy.malls.has(hit.collider.name) && GlobalObjectReferencer.playerShip.linear_velocity.length_squared() < GlobalObjectReferencer.shopping.speedLimit && GlobalObjectReferencer.playerShip.global_transform.origin.distance_squared_to(Economy.malls[hit.collider.name]["loci"]) < GlobalObjectReferencer.shopping.distanceLimit: # opens shop, if hit's a shop
		Input.set_default_cursor_shape(2)
		if leftClick:
			GlobalObjectReferencer.shopping.openShop(hit.collider.name)
	elif hit.collider.has_method("createInfo"):
		Input.set_default_cursor_shape(0)
		if leftClick && GlobalObjectReferencer.shopping.open == null:
			if is_instance_valid(selected):
				selected.removeInfo()
			selected = hit.collider
			info2(selected)
			selected.createInfo(info)
	else:
		Input.set_default_cursor_shape(0)
		if leftClick && GlobalObjectReferencer.shopping.open == null:
			if is_instance_valid(selected):
				selected.removeInfo()
				selected = null
	if GlobalObjectReferencer.shopping.open != null:
		if is_instance_valid(selected):
			selected.removeInfo()
			selected = null
	elif Input.is_mouse_button_pressed(2):
		Input.set_default_cursor_shape(1)
	if is_instance_valid(selected):
		info2(selected)
	if newHovering != hovering:
		if is_instance_valid(hovering):
			hovering.onHover(false)
		hovering = newHovering
		if is_instance_valid(hovering):
			hovering.onHover(true)
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


# Updates cursor size according to the given screen size.
func scaleCursor(screenSize: Vector2):
	var minDim: int = min(screenSize.x, screenSize.y)
	var curDim: int = int(floor(float(minDim) / 33.75))
	curDim = min(curDim, SELECT.get_width())
	var midPix: Vector2 = Vector2(curDim * 0.5, curDim * 0.5)
	midPix = midPix.floor()
	var selectData: Image = SELECT.get_data()
	selectData.resize(curDim, curDim)
	var selectCopy: ImageTexture = ImageTexture.new()
	selectCopy.create_from_image(selectData)
	var attackData: Image = ATTACK.get_data()
	attackData.resize(curDim, curDim)
	var attackCopy: ImageTexture = ImageTexture.new()
	attackCopy.create_from_image(attackData)
	var buildData: Image = BUILD.get_data()
	buildData.resize(curDim, curDim)
	var buildCopy: ImageTexture = ImageTexture.new()
	buildCopy.create_from_image(buildData)
	Input.set_custom_mouse_cursor(selectCopy, 0)
	Input.set_custom_mouse_cursor(attackCopy, 1, midPix)
	Input.set_custom_mouse_cursor(buildCopy, 2)


# Changes the selected deck number to the given integer.
func selectDeck(deckNumber: int):
	selectedDeckNumber = deckNumber
