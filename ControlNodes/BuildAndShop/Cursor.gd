extends Control

# these are textures for cursor shapes
const SELECT: Texture = preload("res://ControlNodes/Images/cursor.png")
const ATTACK: Texture = preload("res://ControlNodes/Images/attackCursor.png")
const BUILD: Texture = preload("res://ControlNodes/Images/shoppingCursor.png")
const HAND: Texture = preload("res://ControlNodes/Images/cursorHand.png")

# these are some other variables
var camera: Camera # used for raycasting and such
var viewport: Viewport # used for raycasting and such
var viewportContainer: ViewportContainer # used for stretch related calculations
var spaceState: PhysicsDirectSpaceState # used during raycasting
var selectedDeckNumber: int # number of the deck which is currently selected
var hit: Dictionary = {} # last raycast hit
var selected = null # object that is selected (for infoBox)
var hovering = null # object that is being hovered
var info: Control = null # reference node for infobox to show up at
var size: Vector2 = Vector2.ZERO # screen size for deciding cursor size

# these are input related variables
var leftClick: bool = false
var rightClick: bool = false
var scrollUp: bool = false
var scrollDown: bool = false


# Called when the node enters the scene tree for the first time.
func _ready():
	camera = GlobalObjectReferencer.camera
	viewport = camera.get_viewport()
	viewportContainer = viewport.get_parent()
	spaceState = camera.get_world().direct_space_state
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
	# raycasts to set the dictionary called hit
	if GlobalObjectReferencer.itemShop.open == null:
		scan()
	else:
		hit.clear()
	# defining new potential hovering object to change highlighted object
	var newHovering = null
	# getting new hovering object if available
	if !hit.empty() && hit.collider.has_method("onHover"):
		newHovering = hit.collider
	# doing some other stuff, depending on if hit is a shop or item or whatnot
	if hit.empty():
		Input.set_default_cursor_shape(0)
		if leftClick:
			if is_instance_valid(selected):
				selected.removeInfo()
				selected = null
	elif Economy.malls.has(hit.collider.name) && GlobalObjectReferencer.playerShip.linear_velocity.length_squared() < GlobalObjectReferencer.shopping.speedLimit && GlobalObjectReferencer.playerShip.global_transform.origin.distance_squared_to(Economy.malls[hit.collider.name]["loci"]) < GlobalObjectReferencer.shopping.distanceLimit: # opens shop, if hit's a shop
		Input.set_default_cursor_shape(2)
		if leftClick:
			GlobalObjectReferencer.shopping.openShop(hit.collider.name)
	elif Economy.cmalls.has(hit.collider.name) && GlobalObjectReferencer.playerShip.linear_velocity.length_squared() < GlobalObjectReferencer.shopping.speedLimit && GlobalObjectReferencer.playerShip.global_transform.origin.distance_squared_to(Economy.cmalls[hit.collider.name]["loci"]) < GlobalObjectReferencer.shopping.distanceLimit: # opens shop, if hit's a shop
		Input.set_default_cursor_shape(2)
		if leftClick:
			GlobalObjectReferencer.itemShop.openShop(hit.collider.name)
	elif Economy.taverns.has(hit.collider.name) && GlobalObjectReferencer.playerShip.linear_velocity.length_squared() < GlobalObjectReferencer.shopping.speedLimit && GlobalObjectReferencer.playerShip.global_transform.origin.distance_squared_to(Economy.taverns[hit.collider.name]["loci"]) < GlobalObjectReferencer.shopping.distanceLimit: # opens shop, if hit's a shop
		Input.set_default_cursor_shape(2)
		if leftClick:
			GlobalObjectReferencer.tavern.openShop(hit.collider.name)
	elif hit.collider.has_method("createInfo"):
		Input.set_default_cursor_shape(3)
		if leftClick && GlobalObjectReferencer.shopping.open == null:
			if is_instance_valid(selected):
				selected.removeInfo()
			selected = hit.collider
			info2(selected)
			selected.createInfo(info)
	else: # means hit is not empty yet it's not something we can work on
		Input.set_default_cursor_shape(0)
		if leftClick && GlobalObjectReferencer.shopping.open == null:
			if is_instance_valid(selected):
				selected.removeInfo()
				selected = null
	# if shopping or building screen is open, then some stuff may need to be handled here, like closing any open infobox
	if GlobalObjectReferencer.shopping.open != null:
		if is_instance_valid(selected):
			selected.removeInfo()
			selected = null
	elif Input.is_mouse_button_pressed(2): # attack cursor shape shows up only if no shop is open, and holding right click
		Input.set_default_cursor_shape(1)
	# setting infobox location to cursor's projection
	if is_instance_valid(selected):
		info2(selected)
	# changing hovered color etc.
	if newHovering != hovering:
		if is_instance_valid(hovering):
			hovering.onHover(false)
		hovering = newHovering
		if is_instance_valid(hovering):
			hovering.onHover(true)
	# resetting input related variables to be ready for the next physics frame
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
	# if !hit.empty():
	# 	print(hit.collider.name)



# Updates location of infobox to hover above the given thing.
func info2(thing):
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
	
	var handData: Image = HAND.get_data()
	handData.resize(curDim, curDim)
	var handCopy: ImageTexture = ImageTexture.new()
	handCopy.create_from_image(handData)

	Input.set_custom_mouse_cursor(selectCopy, 0)
	Input.set_custom_mouse_cursor(attackCopy, 1, midPix)
	Input.set_custom_mouse_cursor(buildCopy, 2)
	Input.set_custom_mouse_cursor(handCopy, 3)


# Changes the selected deck number to the given integer.
func selectDeck(deckNumber: int):
	selectedDeckNumber = deckNumber
