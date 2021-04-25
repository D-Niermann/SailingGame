extends Control


const CURRENCY: String = "g"
const ITEM: PackedScene = preload("res://ControlNodes/BuildAndShop/listItem.tscn")
const TYPE: PackedScene = preload("res://ControlNodes/BuildAndShop/tabsType.tscn")

var infoBoxPlaceholder = null
var open = null
var tabs = null
var list = null
var filter = null
var seller = null
var selected = null
var connected = null
var indicator = null
var viewport: Viewport

const TILEWIDTH: float = 0.2 # width of one tile which all items must be designed accordingly
const STACKED: bool = false
var target = null
var selected_deck : int = -1 # index of the  get_tree().get_nodes_in_group("PlayerDeck") array
var highlight = null
var hologram = null
var resource = null
var parent = null
var coords = null
var xform = null
var angle = 0.0
var rot = 0.0
var size = Vector3.ONE # in terms of tile size given above, each component must be an integer
var rotSize = Vector3.ONE
var switch: bool = true
var toggled = null

var leftClick: bool = false
var rightClick: bool = false
var scrollUp: bool = false
var scrollDown: bool = false


# Called when the node enters the scene tree for the first time.
func _ready():
	seller = get_node("Shop/Sell")
	connected = "bananaTown"
	indicator = get_node("Indicator")
	tabs = get_node("Shop/Tabs/Container")
	list = get_node("Shop/List/Container")
	infoBoxPlaceholder = get_node("Info")
	viewport = get_tree().get_root().get_node("GameWorld/ViewportContainer/Viewport")

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
	if selected_deck!=-1:
		target = get_tree().get_nodes_in_group("PlayerDeck")[selected_deck]
	# if connected != null:
	# 	if open == null:
	# 		indicator.visible = true
	# 	else:
	# 		indicator.visible = false
	# else:
	# 	indicator.visible = false
	# 	if open != null:
	# 		closeShop()
	if selected != null && (rightClick || switch == false):
		selected = null
	if open == null || selected == null:
		deselect()
	elif resource == null:
		var itemName: String = selected.get_node("Name").text
		var good: Dictionary = Economy.goods[itemName]
		hologramFromResource(good["res"])
	if open != null && infoBoxPlaceholder.visible:
		toggle(null)
	if switch == true && target == null:
		if highlight != null:
			var sprite = highlight.get_node("Sprite3D")
			sprite.modulate = Color(1.0, 1.0, 1.0, 1.0)
			highlight = null
			placeOrDestroyHologram()
		return
	if open == null:
		if highlight != null:
			var sprite = highlight.get_node("Sprite3D")
			sprite.modulate = Color(1.0, 1.0, 1.0, 1.0)
			highlight = null
		if resource != null || hologram != null:
			placeOrDestroyHologram()
#		return
	var layer = 0b1
	if hologram != null: 
		if selected_deck == 0:
			layer = 0b10000000000000000000
		elif selected_deck == 1:
			layer = 0b01000000000000000000
		elif selected_deck == 2:
			layer = 0b00100000000000000000
		elif selected_deck == 3:
			layer = 0b00010000000000000000
		elif selected_deck == 4:
			layer = 0b00001000000000000000
	var camera: Camera = viewport.get_camera()
	var spaceState: PhysicsDirectSpaceState = camera.get_world().direct_space_state
	var viewportContainer: ViewportContainer = viewport.get_parent()
	if toggled == null:
		if infoBoxPlaceholder.visible:
			toggle(null)
	else:
		var pos: Vector2 = camera.unproject_position(toggled.global_transform.origin)
		infoBoxPlaceholder.rect_position = Vector2(clamp(pos.x, 0, viewport.size.x), clamp(pos.y, 0, viewport.size.y)) * viewportContainer.stretch_shrink
	var cursor = get_viewport().get_mouse_position() / viewportContainer.stretch_shrink
	var hit: Dictionary
	var toIgnore: Array = [hologram]
	var from = camera.project_ray_origin(cursor)
	var toward = camera.project_ray_normal(cursor)
	var upward = target.global_transform.basis.y.normalized()
	hit = spaceState.intersect_ray(from, from+toward*2000, toIgnore, layer)
	while (hologram == null || !is_instance_valid(hologram)) && !hit.empty() && hit.collider.get_parent() != target:
		toIgnore.append(hit.collider)
		hit = spaceState.intersect_ray(from, from+toward*2000, toIgnore, layer)
	var newHighlight = null
	if hologram != null:
		if scrollUp:
			rot += PI * 0.5
			rotSize = Vector3(rotSize.z, size.y, rotSize.x)
		elif scrollDown:
			rot -= PI * 0.5
			rotSize = Vector3(rotSize.z, size.y, rotSize.x)
		var canPlace = false
		if !hit.empty() && (STACKED || hit.collider == target):
			# print("hit")
			var offset = Vector3(fmod(rotSize.x, 2), 0, fmod(rotSize.z, 2)) * TILEWIDTH * 0.5 + TILEWIDTH * Vector3.UP * (size.y/2)
			var partition: Vector3 = (target.global_transform.xform_inv(hit.position) / TILEWIDTH).floor()
			hologram.global_transform.origin = target.global_transform.xform(partition * TILEWIDTH + offset)
			hologram.global_transform.basis = target.global_transform.basis.rotated(upward, rot)
			var collision: KinematicCollision = hologram.move_and_collide(Vector3(0,0.01,0), false, false, true)
			if !collision:
				canPlace = true
				# print("canPlace")
		if rightClick:
			if parent != null:
				placeOrDestroyHologram()
		elif canPlace:
			var sprite = hologram.get_node("Sprite3D")
			sprite.modulate = Color(0.0, 1.0, 0.0, 0.5)
			if leftClick:
				parent = target
				coords = hologram.global_transform.origin -  parent.global_transform.origin
				xform = hologram.transform
				angle = rot
				placeOrDestroyHologram()
		else:
			var sprite = hologram.get_node("Sprite3D")
			sprite.modulate = Color(1.0, 0.0, 0.0, 0.5)
	else:
		if !hit.empty() && hit.collider.get("isHuman") != null: #check if hit is human
			if hit.collider.get("isHuman")==true && leftClick && open == null:
				toggle(hit.collider)
		elif !hit.empty() && hit.collider.get("movable") != null: # checks if hit is an item
			if open != null && hit.collider.get("movable") == true:
				var temp = hit.collider.get_parent()
				if temp != null && temp == target:
					if leftClick:
						resource = null
						hologram = hit.collider
						hologram.onRemove()
						var mall: Dictionary = Economy.malls[open]
						var itemName = Utility.resName(hologram.name)
						var itemPrice = Economy.getPrice(itemName, open)
						if itemPrice <= mall["money"] && !mall["black"].has(itemName) && mall["white"].has(Economy.goods[itemName]["type"]):
							seller.text = str(itemPrice) + CURRENCY
							seller.disabled = false
						else:
							seller.disabled = true
						parent = temp
						coords = hologram.global_transform.origin - parent.global_transform.origin
						xform = hologram.transform
						angle = -Utility.signedAngle(parent.global_transform.basis.x.normalized(), hologram.global_transform.basis.x.normalized(), parent.global_transform.basis.y.normalized())
						setSize()
						rot = angle
					else:
						newHighlight = hit.collider
			elif open == null && leftClick:
				toggle(hit.collider)
		else:
			if leftClick:
				toggle(null)
	if is_instance_valid(highlight):
		var sprite = highlight.get_node("Sprite3D")
		if sprite!=null:
			sprite.modulate = Color(1.0, 1.0, 1.0, 1.0)
		highlight = null
	if is_instance_valid(newHighlight):
		highlight = newHighlight
	if is_instance_valid(highlight):
		var sprite = highlight.get_node("Sprite3D")
		if sprite!=null:
			sprite.modulate = Color(1.0, 1.0, 0.0, 1.0)
	if selected_deck==-1:
		closeShop()
	leftClick = false
	rightClick = false
	scrollUp = false
	scrollDown = false


# Spawns and sets an external body as the hologram to be placed. May be useful at store/market.
func hologramFromResource(path: String):
	seller.text = "SELL"
	seller.disabled = true
	if resource != null:
		hologram.queue_free()
		hologram = null
	resource = path
	hologram = load(path).instance()
	viewport.add_child(hologram)
	parent = null
	coords = null
	xform = null
	angle = 0.0
	var itemName: String = Utility.resName(hologram.name)
	size = Economy.getSize(itemName)
	if size is Vector2:
		size = Vector3(size.x, 1.0, size.y)
	hologram.global_transform.basis = target.global_transform.basis
	rotSize = size
	rot = 0.0
	var shape = hologram.get_node("CollisionShape").shape
	if shape is BoxShape:
		shape.extents = Vector3(size.x, size.y, size.z) * 0.5 * TILEWIDTH - Vector3.ONE * 0.01
	var gridMesh = hologram.get_node_or_null("GridShowMesh")
	if gridMesh != null:
		gridMesh.visible = true
		gridMesh.scale = Vector3(size.x, size.y, size.z) * TILEWIDTH - Vector3.ONE * 0.005


# Destroys any hologram or resource.
func destroyHologram():
	parent = null
	placeOrDestroyHologram()


# Places current hologram or destroys it.
func placeOrDestroyHologram():
	get_tree().set_input_as_handled()
	seller.text = "SELL"
	seller.disabled = true
	if resource != null:
		if parent != null:
			var duplicate = load(resource).instance()
			if duplicate.get_parent() != parent:
				parent.add_child(duplicate)
			duplicate.global_transform.origin = coords + parent.global_transform.origin
			duplicate.global_transform.basis = parent.global_transform.basis.rotated(parent.global_transform.basis.y.normalized(), angle)
			parent = null
			duplicate.onPlacement()
			purchase(duplicate)
		else:
			resource = null
			if hologram != null:
				hologram.queue_free()
				hologram = null
			coords = null
			xform = null
			angle = null
			size = null
			rot = null
			rotSize = null
		return
	elif parent != null:
		if hologram.get_parent() != parent:
			parent.add_child(hologram)
		hologram.global_transform.origin = coords + parent.global_transform.origin
		hologram.global_transform.basis = parent.global_transform.basis.rotated(parent.global_transform.basis.y.normalized(), angle)
		hologram.transform = xform
		var sprite = hologram.get_node("Sprite3D")
		sprite.modulate = Color(1.0, 1.0, 1.0, 1.0)
		hologram.onPlacement()
	elif hologram != null:
		hologram.queue_free()
		hologram = null
	hologram = null
	parent = null
	coords = null
	xform = null
	angle = null
	size = null
	rot = null
	rotSize = null


# Sets size and rotated size for the selected item.
func setSize():
	var itemName: String = Utility.resName(hologram.name)
	size = Economy.getSize(itemName)
	if size is Vector2:
		size = Vector3(size.x, 1.0, size.y)
	var temp = -Utility.signedAngle(parent.global_transform.basis.x.normalized(), hologram.global_transform.basis.x.normalized(), parent.global_transform.basis.y.normalized())
	var tempToo: Vector2 = Vector2(size.x, size.z).rotated(temp).round().abs()
	rotSize = Vector3(tempToo.x, 1.0, tempToo.y)
	var shape = hologram.get_node("CollisionShape").shape
	if shape is BoxShape:
		shape.extents = Vector3(size.x, size.y, size.z) * 0.5 * TILEWIDTH - Vector3.ONE * 0.01
	var gridMesh = hologram.get_node_or_null("GridShowMesh")
	if gridMesh != null:
		gridMesh.visible = true
		gridMesh.scale = Vector3(size.x, size.y, size.z) * TILEWIDTH - Vector3.ONE * 0.005


# Updates the shopping line for the open shopping screen.
func updateLine(item: Button):
	if open == null:
		return
	var mall: Dictionary = Economy.malls[open]
	var goods: Dictionary = mall["goods"]
	var itemName = item.get_node("Name").text
	if !goods.has(itemName):
		item.queue_free()
		selected = null
		return
	if filter != null && Economy.getType(itemName) != filter:
		item.queue_free()
		selected = null
		return
	var amount = Economy.getAmount(itemName, open)
	if amount <= 0:
		item.queue_free()
		selected = null
		return
	elif amount == INF:
		amount = "INF"
	else:
		amount = "x" + str(amount)
	item.get_node("Amount").text = amount
	var price = Economy.getPrice(itemName, open)
	item.get_node("Price").text = str(price) + CURRENCY
	if price > Economy.money:
		item.disabled = true
		if item == selected:
			deselect()
	else:
		item.disabled = false


# Updates the shopping list for the open shopping screen.
func updateList():
	if open == null:
		return
	var mall: Dictionary = Economy.malls[open]
	var goods: Dictionary = mall["goods"]
	var items: Dictionary = {}
	for item in list.get_children():
		var itemName = item.get_node("Name").text
		items[itemName] = null
		if !goods.has(itemName):
			item.queue_free()
			selected = null
			continue
		if filter != null && Economy.getType(itemName) != filter:
			item.queue_free()
			selected = null
			continue
		var amount = Economy.getAmount(itemName, open)
		if amount <= 0:
			item.queue_free()
			selected = null
			continue
		elif amount == INF:
			amount = "INF"
		else:
			amount = "x" + str(amount)
		item.get_node("Amount").text = amount
		var price = Economy.getPrice(itemName, open)
		item.get_node("Price").text = str(price) + CURRENCY
		if price > Economy.money:
			item.disabled = true
			if item == selected:
				deselect()
		else:
			item.disabled = false
	for good in goods.keys():
		if filter != null && Economy.getType(good) != filter:
			continue
		if items.has(good):
			continue
		var amount = Economy.getAmount(good, open)
		if amount <= 0:
			continue
		elif amount == INF:
			amount = "INF"
		else:
			amount = "x" + str(amount)
		var item = ITEM.instance()
		list.add_child(item)
		item.get_node("Name").text = good
		item.get_node("Amount").text = amount
		var price = Economy.getPrice(good, open)
		item.get_node("Price").text = str(price) + CURRENCY
		item.get_node("Icon").texture = load(Economy.getIcon(good))
		item.connect("pressed", self, "pressed", [item])
		if price > Economy.money:
			item.disabled = true
			if item == selected:
				deselect()
		else:
			item.disabled = false


# Opens the given shop.
func openShop(shop: String):
	if selected_deck == -1:
		selected_deck = 0
		target = get_tree().get_nodes_in_group("PlayerDeck")[selected_deck]
	if open != null:
		closeShop()
	var mall: Dictionary = Economy.malls[shop]
	var index = 0
	for white in mall["white"]:
		var type = TYPE.instance()
		tabs.add_child(type)
		type.get_node("Name").text = white
		type.connect("pressed", self, "pressed", [type])
		if index == 0:
			type.pressed = true
			filter = type.get_node("Name").text
		index += 1
	var goods: Dictionary = mall["goods"]
	for good in goods.keys():
		if filter != null && Economy.getType(good) != filter:
			continue
		var amount = Economy.getAmount(good, shop)
		if amount <= 0:
			continue
		elif amount == INF:
			amount = "INF"
		else:
			amount = "x" + str(amount)
		var item = ITEM.instance()
		list.add_child(item)
		item.get_node("Name").text = good
		item.get_node("Amount").text = amount
		var price = Economy.getPrice(good, shop)
		item.get_node("Price").text = str(price) + CURRENCY
		item.get_node("Icon").texture = load(Economy.getIcon(good))
		item.connect("pressed", self, "pressed", [item])
		if price > Economy.money:
			item.disabled = true
			if item == selected:
				deselect()
		else:
			item.disabled = false
	get_node("Shop").visible = true
	get_tree().get_root().get_node("GameWorld/ViewportContainer/Viewport/GameCamera").selectDeck(selected_deck)
	open = shop


# Closes any open shop.
func closeShop():
	get_node("Shop").visible = false
	for item in list.get_children():
		item.queue_free()
		selected = null
	for type in tabs.get_children():
		type.queue_free()
	open = null
	deselect()
	return


# Called when an item is pressed on the shop.
func pressed(thing):
	if thing.get_node_or_null("Price") != null:
		if selected != null:
			destroyHologram()
		selected = thing
	else:
		for tab in tabs.get_children():
			if tab != thing:
				tab.pressed = false
			else:
				tab.pressed = true
		if filter == null || filter != thing.get_node("Name").text:
			filter = thing.get_node("Name").text
			if selected != null:
				destroyHologram()
			updateList()


# Deselects items.
func deselect():
	selected = null
	if resource != null:
		destroyHologram()


# Removes selected item from the open shop, and handles payment.
func purchase(node: Node):
	if open == null || selected == null:
		return
	var itemName = selected.get_node("Name").text
	node.name = itemName
	var itemPrice = float(selected.get_node("Price").text.rstrip(CURRENCY))
	Economy.money -= itemPrice
	var mall: Dictionary = Economy.malls[open]
	mall["goods"][itemName] -= 1
	mall["money"] += itemPrice
	updateList()


# Sells selected item to the open shop.
func sell():
	if hologram != null:
		if resource == null:
			var itemName: String = Utility.resName(hologram.name)
			var mall: Dictionary = Economy.malls[open]
			var itemPrice = Economy.getPrice(itemName, open)
			if itemPrice <= mall["money"] && !mall["black"].has(itemName) && mall["white"].has(Economy.goods[itemName]["type"]):
				mall["money"] -= itemPrice
				mall["goods"][itemName] += 1
				Economy.money += itemPrice
				destroyHologram()
				updateList()


# Changes toggled item that information will be shown about.
func toggle(thing):
	if toggled == null || thing != toggled:
		# infoBoxPlaceholder.visible = false
		for child in infoBoxPlaceholder.get_children(): # TODO: is this necessary now if we dont do the add_child(rect) below?
			child.queue_free()
	if toggled!=null:
		toggled.removeInfo()	
	toggled = thing
	if toggled != null:
		## set position of infoBoxPlaceholder so that the infoBoxPlaceholder panel is not spawned at old position
		var camera: Camera = viewport.get_camera()
		var viewportContainer: ViewportContainer = viewport.get_parent()
		var pos: Vector2 = camera.unproject_position(toggled.global_transform.origin)
		infoBoxPlaceholder.rect_position = Vector2(clamp(pos.x, 0, viewport.size.x), clamp(pos.y, 0, viewport.size.y)) * viewportContainer.stretch_shrink
		infoBoxPlaceholder.visible = true
		# then create infoBoxPlaceholder box
		thing.createInfo(infoBoxPlaceholder)


func _on_indicator():
	if open==null: #if shop is closed
		openShop(connected) # connects=name of shop, defined in _ready() for now.
	else:
		closeShop()


# Changes chosen deck.
func selectDeck(deckNumber):
	selected_deck = deckNumber
