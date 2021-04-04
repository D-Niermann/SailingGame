extends Control


const CURRENCY: String = "g"
const ITEM: PackedScene = preload("res://listItem.tscn")
const TYPE: PackedScene = preload("res://tabsType.tscn")

var open = null
var tabs = null
var list = null
var filter = null
var seller = null
var selected = null
var connected = null
var indicator = null
var viewport: Viewport

const TEXTUREWIDTH: float = 64.0 # number of pixels in texture which will be considered as one tile
const TILEWIDTH: float = 0.2 # width of one tile which all items must be designed accordingly
const STACKED: bool = false
var target = null
var selected_deck : int = -1 # index of the  get_tree().get_nodes_in_group("PlayerDeck") array
var highlight = null
var hologram = null
var resource = null
var parent = null
var coords = null
var angle = 0.0
var rot = 0.0
var size = Vector3.ONE # in terms of tile size given above, each component must be an integer
var rotSize = Vector3.ONE
var extra = -0.45 # height offset for three dimensional sprites and such
var switch: bool = true

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
	viewport = get_tree().get_root().get_node("GameWorld/ViewportContainer/Viewport")

# Catches only the input which has not been handled yet.
func _unhandled_input(event):
	if event.is_action_pressed("leftClick") && !event.is_echo():
		leftClick = true
	if event.is_action_pressed("rightClick") && !event.is_echo():
		rightClick = true
	if event.is_action_released("scrollUp"):
		scrollUp = true
	if event.is_action_released("scrollDown"):
		scrollDown = true


# Called every physics frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):
	if selected_deck!=-1:
		target = get_tree().get_nodes_in_group("PlayerDeck")[selected_deck] 
	if connected != null:
		if open == null:
			indicator.visible = true
		else:
			indicator.visible = false
	else:
		indicator.visible = false
		if open != null:
			closeShop()
	if selected != null && (rightClick || switch == false):
		selected = null
	if open == null || selected == null:
		deselect()
	elif resource == null:
		var itemName: String = selected.get_node("Name").text
		var good: Dictionary = Economy.goods[itemName]
		hologramFromResource(good["res"])
	if switch == true && target == null:
		if highlight != null:
			var sprite = highlight.get_node("Sprite3D")
			sprite.modulate = Color(1.0, 1.0, 1.0, 1.0)
			highlight = null
			placeOrDestroyHologram()
		return
	var layer = 0b10000000000000000000

	# if hologram != null: 
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
	var cursor = get_viewport().get_mouse_position() / viewportContainer.stretch_shrink
	var hit: Dictionary
	var from = camera.project_ray_origin(cursor)
	var toward = camera.project_ray_normal(cursor)
	var upward = target.global_transform.basis.y.normalized()
	# var intersection = Plane(target.global_transform.origin, target.global_transform.origin + target.global_transform.basis.x, target.global_transform.origin + target.global_transform.basis.z).intersects_ray(from, toward)
	# if intersection != null:
	hit = spaceState.intersect_ray(from, from+toward*2000, [hologram], layer)
	var newHighlight = null
	if hologram != null:
		if scrollUp:# Input.is_action_just_released("scrollUp"):
			rot += PI * 0.5
			rotSize = Vector3(rotSize.z, size.y, rotSize.x)
		elif scrollDown:# Input.is_action_just_released("scrollDown"):
			rot -= PI * 0.5
			rotSize = Vector3(rotSize.z, size.y, rotSize.x)
		var canPlace = false
		if !hit.empty() && (STACKED || hit.collider == target):
			print("hit")
			var offset = Vector3(fmod(rotSize.x, 2), 0, fmod(rotSize.z, 2)) * TILEWIDTH * 0.5 + TILEWIDTH * Vector3.UP * (size.y + extra)
			var partition: Vector3 = (target.global_transform.xform_inv(hit.position) / TILEWIDTH).floor()
			hologram.global_transform.origin = target.global_transform.xform(partition * TILEWIDTH + offset)
			hologram.global_transform.basis = target.global_transform.basis.rotated(upward, rot)

			"""
			I dont get this part, it can be left out? Better performance
			"""
			# var downward = -hologram.global_transform.basis.y.normalized() * (size.y * TILEWIDTH * 0.5 + TILEWIDTH * 0.25 - TILEWIDTH * extra)
			# var backward = hologram.global_transform.basis.z.normalized() * (size.z * 0.5 * TILEWIDTH - 0.05 * TILEWIDTH)
			# var leftward = hologram.global_transform.basis.x.normalized() * (size.x * 0.5 * TILEWIDTH - 0.05 * TILEWIDTH)
			# var originOfRay = hologram.global_transform.origin - leftward
			# hit = spaceState.intersect_ray(originOfRay, originOfRay + downward, [hologram], layer)
			# if !hit.empty() && hit.collider == target:
			# 	originOfRay = hologram.global_transform.origin - backward
			# 	hit = spaceState.intersect_ray(originOfRay, originOfRay + downward, [hologram], layer)
			# 	if !hit.empty() && hit.collider == target:
			# 		originOfRay = hologram.global_transform.origin + leftward
			# 		hit = spaceState.intersect_ray(originOfRay, originOfRay + downward, [hologram], layer)
			# 		if !hit.empty() && hit.collider == target:
			# 			originOfRay = hologram.global_transform.origin + backward
			# 			hit = spaceState.intersect_ray(originOfRay, originOfRay + downward, [hologram], layer)
			# 			if !hit.empty() && hit.collider == target:
			# 				print("almost")
			"""
			##########################################
			"""
			var collision: KinematicCollision = hologram.move_and_collide(Vector3.ZERO, false, false, true)
			if !collision:
				canPlace = true
				print("canPlace")
		if rightClick:
			if parent != null:
				placeOrDestroyHologram()
		elif canPlace:
			var sprite = hologram.get_node("Sprite3D")
			sprite.modulate = Color(0.0, 1.0, 0.0, 0.5)
			if leftClick:
				parent = target
				coords = hologram.global_transform.origin -  parent.global_transform.origin
				angle = rot
				placeOrDestroyHologram()
		else:
			var sprite = hologram.get_node("Sprite3D")
			sprite.modulate = Color(1.0, 0.0, 0.0, 0.5)
	else:
		if !hit.empty():
			var temp = hit.collider.get_parent()
			if temp != null && temp == target:
				if leftClick:
					resource = null
					hologram = hit.collider
					var mall: Dictionary = Economy.malls[open]
					var itemName = Utility.resName(hologram.name)
					var itemPrice = Economy.getPrice(itemName, open)
					if itemPrice <= mall["money"] && !mall["black"].has(itemName) && mall["white"].has(Economy.goods[itemName]["type"]):
						seller.text = itemPrice + CURRENCY
						seller.disabled = false
					else:
						seller.disabled = true
					parent = temp
					coords = hologram.global_transform.origin - parent.global_transform.origin
					angle = -Utility.signedAngle(parent.global_transform.basis.x.normalized(), hologram.global_transform.basis.x.normalized(), parent.global_transform.basis.y.normalized())
					setSize()
					rot = angle
				else:
					newHighlight = hit.collider
	if highlight != null:
		var sprite = highlight.get_node("Sprite3D")
		sprite.modulate = Color(1.0, 1.0, 1.0, 1.0)
		highlight = null
	if newHighlight != null:
		highlight = newHighlight
	if highlight != null:
		var sprite = highlight.get_node("Sprite3D")
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
	resource = path
	hologram = load(path).instance()
	viewport.add_child(hologram)
	parent = null
	coords = null
	angle = 0.0
	var sprite: Sprite3D = hologram.get_node("Sprite3D")
	var dimensions: Vector2 = sprite.texture.get_size() / TEXTUREWIDTH
	size = Vector3(dimensions.x, 1.0, dimensions.y)
	hologram.global_transform.basis = target.global_transform.basis
	rotSize = size
	rot = 0.0


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
			purchase(duplicate)
		else:
			resource = null
			if hologram != null:
				hologram.queue_free()
				hologram = null
			coords = null
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
		var sprite = hologram.get_node("Sprite3D")
		sprite.modulate = Color(1.0, 1.0, 1.0, 1.0)
	elif hologram != null:
		hologram.queue_free()
	hologram = null
	parent = null
	coords = null
	angle = null
	size = null
	rot = null
	rotSize = null


# Sets size and rotated size for the selected item.
func setSize():
	var sprite: Sprite3D = hologram.get_node("Sprite3D")
	var dimensions: Vector2 = sprite.texture.get_size() / TEXTUREWIDTH
	size = Vector3(dimensions.x, 1.0, dimensions.y)
	var temp = -Utility.signedAngle(parent.global_transform.basis.x.normalized(), hologram.global_transform.basis.x.normalized(), parent.global_transform.basis.y.normalized())
	dimensions = dimensions.rotated(temp).round().abs()
	rotSize = Vector3(dimensions.x, 1.0, dimensions.y)


# Updates the shopping line for the open shopping screen.
func updateLine(item: Button):
	if open == null:
		return
	var mall: Dictionary = Economy.malls[open]
	var goods: Dictionary = mall["goods"]
	var itemName = item.get_node("Name").text
	if !goods.has(itemName):
		item.queue_free()
		return
	if filter != null && Economy.getType(itemName) != filter:
		item.queue_free()
		return
	var amount = Economy.getAmount(itemName, open)
	if amount <= 0:
		item.queue_free()
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
			continue
		if filter != null && Economy.getType(itemName) != filter:
			item.queue_free()
			continue
		var amount = Economy.getAmount(itemName, open)
		if amount <= 0:
			item.queue_free()
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
	selected_deck = 0
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
	open = shop


# Closes any open shop.
func closeShop():
	get_node("Shop").visible = false
	for item in list.get_children():
		item.queue_free()
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


func indicator():
	openShop(connected)


func _on_Deck1_button_up():
	selected_deck = 1


func _on_Deck0_button_up():
	selected_deck = 0


func _on_DeckAll_button_up():
	selected_deck = -1
